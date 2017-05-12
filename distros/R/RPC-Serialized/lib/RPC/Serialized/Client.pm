#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/Client.pm $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::Client;
{
  $RPC::Serialized::Client::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized';

use RPC::Serialized::Exceptions;

our $AUTOLOAD;

sub call {
    my $self = shift;
    my $call = shift;

    # this is where we would hack around with the RPC protocol
    # although not the on-the-wire stuff, which is in Serialized.pm
    $self->send( { CALL => $call, ARGS => \@_ } );
    my $reply = $self->recv;

    if ( $reply->{EXCEPTION} ) {
        my $class = $reply->{EXCEPTION}->{CLASS};

        throw_proto 'Invalid or missing CLASS'
            unless $class and $class =~ /^RPC::Serialized::X(::.+)?$/;

        my $message = $reply->{EXCEPTION}->{MESSAGE} || "";
        $class->throw($message);
    }

    return $reply->{RESPONSE};
}

sub AUTOLOAD {
    my $self = shift;

    throw_app 'Object method called on class'
        unless ref($self);

    ( my $call = $AUTOLOAD ) =~ s/^.*:://;
    $self->call( $call, @_ );
}

1;

