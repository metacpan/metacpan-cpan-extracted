package Net::WAMP::Role::Subscriber;

=encoding utf-8

=head1 NAME

Net::WAMP::Role::Subscriber - Subscriber role for Net::WAMP

=head1 SYNOPSIS

    package MyWAMP;

    use parent qw( Net::WAMP::Role::Subscriber );

    sub on_EVENT {
        my ($self, $msg, $SUBSCRIBE_msg) = @_;
        ...
    }

    sub on_SUBSCRIBED {
        my ($self, $msg, $SUBSCRIBE_msg) = @_;
        ...
    }

    sub on_ERROR_SUBSCRIBED {
        my ($self, $ERROR_msg, $SUBSCRIBE_msg) = @_;
        ...
    }

    sub on_UNSUBSCRIBED {
        my ($self, $msg, $UNSUBSCRIBE_msg, $SUBSCRIBE_msg) = @_;
        ...
    }

    sub on_ERROR_UNSUBSCRIBED {
        my ($self, $ERROR_msg, $UNSUBSCRIBE_msg, $SUBSCRIBE_msg) = @_;
        ...
    }

    package main;

    my $wamp = MyWAMP->new( on_send => sub { ... } );

    $wamp->send_SUBSCRIBE( {}, 'some.topic' );

    $wamp->send_UNSUBSCRIBE( $subscr_id );

    #A more convenient alternative to send_UNSUBSCRIBE
    #so you don’t have to track the subscription ID yourself:
    $wamp->send_UNSUBSCRIBE_for_topic( 'some.topic' );

    $wamp->get_SUBSCRIBE( $msg );   #e.g., an EVENT message object
    $wamp->get_SUBSCRIBE( $subscr_id );

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

use constant {
    receiver_role_of_SUBSCRIBE => 'broker',
    receiver_role_of_UNSUBSCRIBE => 'broker',
};

use Net::WAMP::Role::Base::Client::Features ();

BEGIN {
    $Net::WAMP::Role::Base::Client::Features::FEATURES{'subscriber'} = {};
}

sub send_SUBSCRIBE {
    my ($self, $opts_hr, $topic) = @_;

    my $msg = $self->_create_and_send_session_msg(
        'SUBSCRIBE',
        $opts_hr,
        $topic,
    );

    $self->{'_sent_SUBSCRIBE'}{$msg->get('Request')} = $msg;

    return $msg;
}

sub send_UNSUBSCRIBE {
    my ($self, $subscription_id) = @_;

    my $msg = $self->_create_and_send_session_msg(
        'UNSUBSCRIBE',
        $subscription_id,
    );

    $self->{'_sent_UNSUBSCRIBE'}{$msg->get('Request')} = $msg;

    return $msg;
}

sub send_UNSUBSCRIBE_for_topic {
    my ($self, $topic) = @_;

    my $subscrs_hr = $self->{'_subscriptions'};

    for my $subscr_id ( keys %$subscrs_hr ) {
        next if $subscrs_hr->{$subscr_id} ne $topic;
        return $self->send_UNSUBSCRIBE( $subscr_id );
    }

    die "No subscription for topic “$topic”!";
}

sub get_SUBSCRIBE {
    my ($self, $id_or_msg) = @_;

    my $subscr_id = ref($id_or_msg) ? $id_or_msg->get('Subscription') : $id_or_msg;

    return $self->{'_subscriptions'}{ $subscr_id };
}

sub _receive_ERROR_SUBSCRIBE {
    my ($self, $msg) = @_;

    my $orig_msg = delete $self->{'_sent_SUBSCRIBE'}{$msg->get('Request')};
    if (!$orig_msg) {
        warn sprintf 'ERROR message for untracked SUBSCRIBE request ID “%s”!', $msg->get('Request');
    }

    return $orig_msg;
}

sub _receive_SUBSCRIBED {
    my ($self, $msg) = @_;

    my $req_id = $msg->get('Request');

    my $orig_subscr = delete $self->{'_sent_SUBSCRIBE'}{ $req_id };

    if (!$orig_subscr) {
        die "Received SUBSCRIBED for unknown (Request=$req_id)!"; #XXX
    }

    $self->{'_subscriptions'}{ $msg->get('Subscription') } = $orig_subscr;

    return;
}

sub _receive_UNSUBSCRIBED {
    my ($self, $msg) = @_;

    my ( $omsg, $orig_subscr );

    if (my $omsg = delete $self->{'_sent_UNSUBSCRIBE'}{ $msg->get('Request') }) {
        $orig_subscr = delete $self->{'_subscriptions'}{ $omsg->{'Subscription'} };
    }
    else {
        die "Received UNSUBSCRIBED for unknown!"; #XXX
    }

    return;
}

sub _receive_ERROR_UNSUBSCRIBE {
    my ($self, $msg) = @_;

    my $orig_msg = delete $self->{'_sent_UNSUBSCRIBE'}{$msg->get('Request')};
    if (!$orig_msg) {
        warn sprintf 'ERROR message for untracked UNSUBSCRIBE request ID “%s”!', $msg->get('Request');
    }

    return $orig_msg;
}

sub _receive_EVENT {
    my ($self, $msg) = @_;

    my $subscr_id = $msg->get('Subscription');

    my $orig_subscr = $self->{'_subscriptions'}{ $subscr_id };

    if (!$orig_subscr) {
        die "Received EVENT for unknown (Subscription=$subscr_id)!"; #XXX
    }

    return;
}

1;
