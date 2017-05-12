package Net::Stomp::Receipt;

use strict;
use warnings;

#
# Subclass of Net::Stomp for adding "transactional sends"
# with receipt and commit.
#
# Author: Hugo Salgado <huguei@cpan.org>
#
use base 'Net::Stomp';

#
# I start the version in sync with Net::Stomp
# (and hopes to keep it in that way)
our $VERSION = '0.36';


# Added a new configuration variable on creation,
# so we need to subclass the constructor
sub new {
    my ($class, $conf) = @_;

    my $self = $class->SUPER::new({
        hostname => $conf->{'hostname'},
        port => $conf->{'port'},
    });

    # to keep the session id, as will be given from the server
    $self->{'sessionid'} = undef;
    # to keep an incremental for the transaction and receipt ids
    $self->{'serial'}    = 0;

    # and we add the persistent feature on constructor
    $self->{'PERSISTENT'} = 1 if $conf->{'PERSISTENT'};

    bless $self, $class;

    return $self;
}

# We need to set the sessionid on connection time
sub connect {
    my ( $self, $conf ) = @_;

    my $frame = $self->SUPER::connect( $conf );

    # Setting initial values for session id, as given from
    # the stomp server
    $self->{'sessionid'} = $frame->headers->{'session'};

    return $frame;
}

# Internal method for autoincremental serial id
sub _getSerial {
    my $self = shift;

    $self->{'serial'}++;

    return $self->{'serial'};
}

# The new method. We don't override the original "send", so
# we can use one or another.
sub send_safe {
    my ( $self, $conf ) = @_;
    my $body = $conf->{body};
    delete $conf->{body};

    # Transaction begins
    $conf->{transaction} = $self->{'sessionid'} .  '-' .  $self->_getSerial;
    my $frame = Net::Stomp::Frame->new(
        { command => 'BEGIN', headers => $conf } );
    $self->send_frame($frame);
    undef $frame;

    # Sending the message, with receipt header
    my $receipt_id = $self->{'sessionid'} .  '-' .  $self->_getSerial;
    $conf->{receipt} = $receipt_id;
    $conf->{persistent} = 'true' if $self->{'PERSISTENT'};
    $frame = Net::Stomp::Frame->new(
        { command => 'SEND', headers => $conf, body => $body } );
    $self->send_frame($frame);
    undef $frame;
    delete $conf->{receipt};
    delete $conf->{persistent};

    # Checking the server for the right receipt
    # If it's OK -> commit the transaction
    $frame = $self->receive_frame;
    if (($frame->command eq 'RECEIPT') and
        ($frame->headers->{'receipt-id'} eq $receipt_id)) {
        my $frame_commit = Net::Stomp::Frame->new(
            { command => 'COMMIT', headers => $conf } );
        $self->send_frame($frame_commit);

        return 1;
    }

    # whatever else, abort transaction
    my $frame_abort = Net::Stomp::Frame->new(
        { command => 'ABORT', headers => $conf } );
    $self->send_frame($frame_abort);

    return 0;
}


1;

__END__

=head1 NAME

Net::Stomp::Receipt - An extension to Net::Stomp (STOMP client) to allow transactional sends.

=head1 SYNOPSIS

  use Net::Stomp::Receipt;

  my $stomp = Net::Stomp::Receipt->new({
    hostname   => 'localhost',
    port       => '61613',
    PERSISTENT => 1,
  });

  $stomp->connect({
    login    => 'hello',
    passcode => 'there'
  });

  $stomp->send_safe({
    destination => '/queue/foo',
    body => 'test message'
  }) or die "Couldn't send the message!";


=head1 DESCRIPTION

This module is an extension to Net::Stomp module, an Streaming
Text Orientated Messaging Protocol client, that adds a new
method send_safe which uses "transactional sends".

By this way, any message sent to the stomp server is identified
with a transaction id, that must be acked by a server receipt.
In case of failure, the send is aborted.


=head1 SEE ALSO

Net::Stomp module

The protocol spec: http://stomp.codehaus.org/Protocol

=head1 AUTHOR

Hugo Salgado, E<lt>huguei@cpan.org<gt>

=head1 ACKNOWLEDGEMENTS

This module was built for NIC Chile (http://www.nic.cl), who
granted its liberation as free software.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hugo Salgado

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
