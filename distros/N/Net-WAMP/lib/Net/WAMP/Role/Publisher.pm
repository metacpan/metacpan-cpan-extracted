package Net::WAMP::Role::Publisher;

=encoding utf-8

=head1 NAME

Net::WAMP::Role::Publisher - Publisher role for Net::WAMP

=head1 SYNOPSIS

    package MyWAMP;

    use parent qw( Net::WAMP::Role::Publisher );

    sub on_PUBLISHED { ... }

    sub on_ERROR_PUBLISH { ... }

    package main;

    my $wamp = MyWAMP->new( on_send => sub { ... } );

    $wamp->send_PUBLISH( {}, 'some.topic', \@args, \%args_kv );

=head1 DESCRIPTION

See the main L<Net::WAMP> documentation for more background on
how to use this class in your code.

=cut

use strict;
use warnings;

use parent qw(
    Net::WAMP::Role::Base::Client
);

use Module::Load ();

use Types::Serialiser ();

use constant {
    receiver_role_of_PUBLISH => 'broker',
};

use Net::WAMP::Role::Base::Client::Features ();

BEGIN {
    $Net::WAMP::Role::Base::Client::Features::FEATURES{'publisher'}{'features'}{'publisher_exclusion'} = $Types::Serialiser::true;
}

sub send_PUBLISH {
    my ($self, $opts_hr, $topic, @args) = @_;

    #Considered being “nice” and allowing this, but we never know
    #when WAMP might actually try to utilize number or string values.
    #local $opts_hr->{'acknowledge'} = ${ *{$Types::Serialiser::{ $opts_hr->{'acknowledge'} ? 'true' : 'false' }}{'SCALAR'} } if exists $opts_hr->{'acknowledge'};

    my $msg = $self->_create_and_send_session_msg(
        'PUBLISH',
        $opts_hr,
        $topic,
        @args,
    );

    if ($msg->publisher_wants_acknowledgement()) {
        $self->{'_sent_PUBLISH'}{$msg->get('Request')} = $msg;
    }

    return $msg;
}

sub _receive_PUBLISHED {
    my ($self, $msg) = @_;

    if (!delete $self->{'_sent_PUBLISH'}{ $msg->get('Request') }) {
        warn sprintf("Received PUBLISHED for unknown! (%s)", $msg->get('Request')); #XXX
    }

    return;
}

1;
