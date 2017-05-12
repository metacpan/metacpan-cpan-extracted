package Net::APNS::Feedback;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'Net::APNS::Persistent::Base';

use JSON::XS;

# ensure we're in byte-oriented mode
use bytes;

my %defaults = (
    host_production => 'feedback.push.apple.com',
    host_sandbox    => 'feedback.sandbox.push.apple.com',
    port            => 2196,
   );

=head1 NAME

Net::APNS::Feedback - Retrieve data from Apple's APNS feedback service

=head1 SYNOPSIS

  use Net::APNS::Feedback;
  
  my $apns = Net::APNS::Feedback->new({
    sandbox => 1,
    cert    => 'cert.pem',
    key     => 'key.pem',
    passwd  => 'key password',
  });
  
  my @feedback = $apns->retrieve_feedback;

=head1 DESCRIPTION

Apple's APNS system provides a feedback service to let you know the
device rejected notifications because they are no longer wanted
(usually meaning the app has been removed).

L<See the|SEE ALSO> Apple Push Notification Service Programming Guide.

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

defaults to feedback.push.apple.com or feedback.sandbox.push.apple.com depending
on the setting of sandbox. can be set manually.

=item port

defaults to 2196

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

    return $self;
}

=head2 retrieve_feedback

Takes no arguments and returns an arrayref (possibly) containing hashrefs. eg:

  [
    {
      'time_t' => 1259577923,
      'token' => '04ef31c86205...624f390ea878416'
    },
    {
      'time_t' => 1259577926,
      'token' => '04ef31c86205...624f390ea878416'
    },
  ]

C<time_t> is the epoc time of when the notification was rejected. C<token> is
a hex encoded device token for you to reconcile with your data.

As you can see from this example, you can recieve more than one notifications
about the same token if you have had more than one message rejected since you last
checked the feedback service.

Note that once you have drained all the feedback, you will not be delivered the
same set again.

L<See the|SEE ALSO> Apple Push Notification Service Programming Guide.

=cut

sub retrieve_feedback {
    my $self = shift;

    my $data = $self->_read;

    my @res;

    while ($data) {
        my ($time_t, $token_bin);
        ($time_t, $token_bin, $data) = unpack( 'N n/a a*', $data);

        push @res, {
            time_t => $time_t,
            token => unpack( 'H*', $token_bin ),
        };
    }

    return \@res;
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

=item L<Net::APNS::Persistent>

=item GIT Source Repository for this module

L<http://github.com/aufflick/p5-net-apns-persistent>

=back

=head1 AUTHOR

Mark Aufflick, E<lt>mark@aufflick.comE<gt>, L<http://mark.aufflick.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mark Aufflick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
