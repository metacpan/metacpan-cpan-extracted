package Net::APNS::Persistent;

# perl 5.8 required for utf8 safe substr
use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'Net::APNS::Persistent::Base';

use Encode qw(decode encode encode_utf8);

# NB: Using JSON::XS as not all JSON modules allowed
# by JSON::Any do unicode correctly
use JSON::XS;

__PACKAGE__->mk_accessors(qw(
                                devicetoken
                                _queue
                                max_payload_size
                                command
                                _json
                           ));

my %defaults = (
    host_production  => 'gateway.push.apple.com',
    host_sandbox     => 'gateway.sandbox.push.apple.com',
    max_payload_size => 256,
    port             => 2195,
    command          => 0
   );

=head1 NAME

Net::APNS::Persistent - Send Apple APNS notifications over a persistent connection

=head1 SYNOPSIS

  use Net::APNS::Persistent;

  my $devicetoken_hex = '04ef...a878416';
  
  my $apns = Net::APNS::Persistent->new({
    sandbox => 1,
    cert    => 'cert.pem',
    key     => 'key.pem',
    passwd  => 'key password',
  });

  $apns->queue_notification(
    $devicetoken_hex,
    {
      aps => {
          alert => 'sweet!',
          sound => 'default',
          badge => 1,
      },
    });
  
  $apns->send_queue;

  $apns->disconnect;

You can queue more than one notification in one transmission
by calling L<queue_notification> multiple times. If you want to
pass in utf8 text in the alert (either as a string or alert-E<gt>body),
you need to be careful with the encoding. See the test files for an
example of reading utf8 from a text file. You should also be able
to pass utf8 through from eg. a database in a similar way.

You can also use the connection many times (ie. queue then send, queue then send,
ad nauseum). The call to disconnect is not strictly necessary since the object
will disconnect as soon as it falls out of scope.

You can place your own custom data outside the C<aps> hash. L<See the|SEE ALSO>
Apple Push Notification Service Programming Guide for more info.

All methods are fatal on error. Eg. if the ssl connection returns an error,
the code will die. You can either then just restart your script or you can use
C<eval> to catch the exception.

=head1 DESCRIPTION

Class to create a persistent connection to Apple's APNS servers

=head1 METHODS

=head2 new

Args:

=over

=item sandbox

set to true if you want to use the sandbox host. defaults to 0. ignored if you set the host manually

=item cert

path to your certificate

=item cert_type

defaults to PEM - see L<Net::SSLeay>.

=item key

path you your private key

=item key_type

defaults to PEM - see L<Net::SSLeay>.

=item passwd

password for your private key, if required.

=item host

defaults to gateway.push.apple.com or gateway.sandbox.push.apple.com depending
on the setting of sandbox. can be set manually.

=item port

defaults to 2195

=item command

defaults to 0

=back

NB: all these args are available as accessors, but you need to set them before the connection
is first used.

=cut

sub new {
    my ($class, $init_vals) = @_;

    $init_vals ||= {};

    my $self = $class->SUPER::new({

        %defaults,
        
        %{$init_vals}
       });

    $self->_queue([]);

    $self->_json(JSON::XS->new());
    $self->_json->utf8(1);

    return $self;
}

sub _apply_to_alert_body {
    my ($payload, $func) = @_;

    return
      if ! exists $payload->{aps}{alert};
    
    # can be in alert->body, or a plain string in alert
    if (ref $payload->{aps}{alert} eq 'HASH') {
        $payload->{aps}{alert}{body} = $func->($payload->{aps}{alert}{body});
    } else {
        $payload->{aps}{alert} = $func->($payload->{aps}{alert});
    }
}

sub _pack_payload_for_devicetoken {
    my ($self, $devicetoken, $payload) = @_;

    if (ref($payload) ne 'HASH' || ref($payload->{aps}) ne 'HASH') {
        die "Invalid payload: " . Dumper($payload);
    }

    # force badge to be integer
    $payload->{aps}{badge} += 0
      if exists $payload->{aps}{badge};

    # convert message to unicode, after ensuring it was utf8 in the first place
    _apply_to_alert_body($payload, sub {
                             my $str = shift; # decode won't work on string literals
                             encode('unicode', decode('utf8', $str, Encode::FB_CROAK));
                         });

    my $json = $self->_json->encode($payload);

    # enforce max_payload_size
    my $max_payload_size = $self->max_payload_size;
    if ( bytes::length($json) > $max_payload_size ) {
        
        # not sure why this is necessary. Must be something
        # about the difference in density b/n utf8 and unicode?
        # This isn't very efficient,
        # but users shouldn't be passing in huge strings, surely...
        
        while (bytes::length($json) > $max_payload_size) {
            _apply_to_alert_body($payload, sub {
                                     substr($_[0], 0, -1);
                                 });

            $json = JSON::XS::encode_json($payload);
        }
    }

    return pack(
        'c n/a* n/a*',
        $self->command,
        pack( 'H*', $devicetoken ),
        $json
       );
}

=head2 queue_notification

takes two arguments - a device token (as a string representation of hex), and
a hashref with the payload. eg:

  my $devicetoken_hex = '04ef...a878416';

  $apns->queue_notification(
    $devicetoken_hex,
    {
      aps => {
          alert => 'sweet!',
          sound => 'default',
          badge => 1,
      },
    });

  $apns->queue_notification(
    $devicetoken_hex,
    {
      aps => {
          alert => {
              body => 'foo',
              'action-loc-key' => undef,
          },
          sound => 'default',
          badge => 1,
      },
      foo => 'bar',
    });

The second example shows the complex alert format and also custom application
data outside the aps hash.

This method will ensure that the payload is at most 256 bytes by trimming the
alert body. The trimming function is utf8-safe, but not very efficient (so
don't ask it to trim War and Peace).

=cut

sub queue_notification {
    my ($self, $devicetoken, $payload) = @_;

    push @{$self->_queue}, [$devicetoken, $payload];

    return 1;
}

=head2 send_queue

This will actually send the data to the ssl connection.

=cut

sub send_queue {
    my $self = shift;

    my $data = '';

    for my $queue_entry (@{$self->_queue}) {
        my ($devicetoken, $payload) = @{$queue_entry};

        $data .= $self->_pack_payload_for_devicetoken($devicetoken, $payload);
    }

    $self->_send($data)
      if $data;

    $self->_queue([]);

    return 1;
}

=head2 disconnect

Disconnect the ssl connection and socket, and free the ssl structures. This usually
isn't necessary as this will happen implicitly when the object is destroyed.

=head1 SEE ALSO

=over 4

=item Presentation on this module by Author

L<http://mark.aufflick.com/talks/apns>

=item Apple Push Notification Service Programming Guide

L<http://developer.apple.com/IPhone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction/Introduction.html>

=item L<Net::APNS::Feedback>

=item GIT Source Repository for this module

L<http://github.com/aufflick/p5-net-apns-persistent>

=back

=head1 AUTHOR

Mark Aufflick, E<lt>mark@aufflick.comE<gt>, L<http://mark.aufflick.com/>

=head1 CREDITS

Some inspiration came from haoyayoi's L<Net::APNS>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mark Aufflick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
