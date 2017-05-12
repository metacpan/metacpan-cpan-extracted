package Net::WAMP::Role::Broker;

=encoding utf-8

=head1 NAME

Net::WAMP::Role::Broker - Broker role for Net::WAMP

=head1 SYNOPSIS

    package MyRouter;

    use parent qw( Net::WAMP::Role::Router );

    #For security, this defaults to rejecting everything!
    sub deny_PUBLISH {
        my ($self, $SUBSCRIBE_msg) = @_;

        my $session_obj = $self->get_session();

        #success
        return;

        #fail, generic (Error = wamp.error.not_authorized)
        return 1;

        #fail, custom Auxiliary (Error = wamp.error.not_authorized)
        return { foo => 1 };

        #fail, generic Auxiliary, custom Error
        return 1, 'myapp.error.go_away';

        #fail, custom Auxiliary and Error
        return { foo => 1 }, 'myapp.error.go_away';
    }

    #This follows the same pattern as deny_PUBLISH().
    #It also defaults to rejecting everything.
    sub deny_SUBSCRIBE { ... }

=head1 DESCRIPTION

This is an B<EXPERIMENTAL> WAMP Broker implementation. If you use it,
please send feedback!

=head1 AUTHORIZATION

To have a useful Broker you’ll need to create a C<deny_PUBLISH> method,
since the default is to deny all PUBLISH requests.
If that Broker is to allow SUBSCRIBE requests, you’ll also need a
C<deny_SUBSCRIBE()> method. The format of these is described above.

=head1 METHODS

Broker only exposes a few public methods:

=head2 $subscr_id = I<OBJ>->subscribe( SESSION_OBJ, METADATA_HR, TOPIC )

This function subscribes a session to a topic, independently of actual WAMP
messaging. This is useful, e.g., if you want to “auto-subscribe” a session
to a topic.

The return is the same number that is sent in a SUBSCRIBED message’s
C<Subscription>. No SUBSCRIBED message is sent, however.

=head2 I<OBJ>->unsubscribe( SESSION_OBJ, SUBSCR_ID )

Undoes a subscription, without sending an UNSUBSCRIBED message.

=head2 I<OBJ>->publish( SESSION_OBJ, METADATA_HR, TOPIC );

=head2 I<OBJ>->publish( SESSION_OBJ, METADATA_HR, TOPIC, @ARGS );

=head2 I<OBJ>->publish( SESSION_OBJ, METADATA_HR, TOPIC, @ARGS, %ARGS_KV );

Publish a message. The return is the publication ID, which is sent
in the EVENT messages’ C<Publication>.

=cut

use strict;
use warnings;

use Try::Tiny;

use parent qw(
  Net::WAMP::Role::Base::Router
);

use constant {
    deny_SUBSCRIBE => 1,
    deny_PUBLISH => 1,

    receiver_role_of_EVENT => 'subscriber',
    receiver_role_of_SUBSCRIBED => 'subscriber',
    receiver_role_of_UNSUBSCRIBED => 'subscriber',
    receiver_role_of_PUBLISHED => 'publisher',
};

use Types::Serialiser ();

use Net::WAMP::Role::Base::Router::Features ();
use Net::WAMP::Utils ();

BEGIN {
    $Net::WAMP::Role::Base::Router::Features::FEATURES{'broker'}{'features'}{'publisher_exclusion'} = $Types::Serialiser::true;

    return;
}

sub subscribe {
    my ($self, $session, $options, $topic) = @_;

    $self->_validate_uri($topic);

    my $subscribers_hr = $self->_get_topic_subscribers($session, $topic);

    if ($subscribers_hr->{$session}) {
        die "Already subscribed!";
    }

    my $subscription = Net::WAMP::Utils::generate_global_id();

    $self->{'_state'}->set_realm_deep_property(
        $session,
        [ "subscribers_$topic", $session ],
        {
            session => $session,
            options => $options,
            subscription => $subscription,
        },
    );

    $self->{'_state'}->set_realm_property( $session, "subscription_topic_$subscription", $topic );

    return $subscription;
}

sub unsubscribe {
    my ($self, $session, $subscription) = @_;

    my $topic = $self->{'_state'}->unset_realm_property($session, "subscription_topic_$subscription") or do {
        my $realm = $self->_get_realm_for_session($session);
        die Net::WAMP::X->create('NoSuchSubscription', $realm, $subscription);
    };

    $self->{'_state'}->unset_realm_deep_property(
        $session, [ "subscribers_$topic", $session ],
    );

    return;
}

sub publish {
    my ($self, $session, $options, $topic, $args_ar, $args_hr) = @_;

    $self->_validate_uri($topic);

    my $subscribers_hr = $self->_get_topic_subscribers($session, $topic);

    my $publication = Net::WAMP::Utils::generate_global_id();

    for my $rcp (values %$subscribers_hr) {

        #Implements “Publisher Exclusion” feature
        if ( $session eq $rcp->{'session'} ) {
            next if !Types::Serialiser::is_false($options->{'exclude_me'});
            next if !$session->peer_role_supports_boolean('publisher', 'publisher_exclusion');
        }

        local $self->{'_session'} = $rcp->{'session'};

        $self->_send_EVENT(
            $rcp->{'subscription'},
            $publication,
            {}, #TODO ???
            ( $args_ar ? ( $args_ar, $args_hr || () ) : () ),
        );
    }

    return $publication;
}

sub _get_topic_subscribers {
    my ($self, $session, $topic) = @_;

    return $self->{'_state'}->get_realm_property($session, "subscribers_$topic");
}

#sub _get_topic_subscribers_or_die {
#    my ($self, $session, $topic) = @_;
#
#    return $self->_get_topic_subscribers($session, $topic) || do {
#        my $realm = $self->_get_realm_for_session($session);
#        die "Realm “$realm” has no topic “$topic”!";
#    };
#}

#----------------------------------------------------------------------

sub _receive_SUBSCRIBE {
    my ($self, $msg) = @_;

    my ($meta_hr, $error) = $self->deny_SUBSCRIBE($msg);
    if ($meta_hr) {
        $self->_create_and_send_ERROR(
            'SUBSCRIBE',
            $msg->get('Request'),
            ref($meta_hr) ? $meta_hr : {},
            $error || 'wamp.error.not_authorized',
        );

        return;
    }

    my $subscription;

    $self->_catch_exception(
        'SUBSCRIBE',
        $msg->get('Request'),
        sub {
            try {
                $subscription = $self->subscribe(
                    $self->{'_session'},
                    ( map { $msg->get($_) } qw( Options Topic ) ),
                );

                $self->_send_SUBSCRIBED(
                    $msg->get('Request'),
                    $subscription,
                );
            }
            catch {
                if ( try { $_->isa('Net::WAMP::X::BadURI') } ) {
                    $self->_create_and_send_ERROR(
                        'SUBSCRIBE',
                        $msg->get('Request'),
                        {
                            net_wamp_message => $_->get_message(),
                        },
                        'wamp.error.invalid_uri',
                    );
                }
                else {
                    local $@ = $_;
                    die;
                }
            };
        },
    );

    return;
}

sub _send_SUBSCRIBED {
    my ($self, $req_id, $sub_id) = @_;

    return $self->_create_and_send_msg(
        'SUBSCRIBED',
        $req_id,
        $sub_id,
    );
}

sub _receive_UNSUBSCRIBE {
    my ($self, $msg) = @_;

    try {
        $self->unsubscribe(
            $self->{'_session'},
            $msg->get('Subscription'),
        );

        $self->_send_UNSUBSCRIBED( $msg->get('Request') );
    }
    catch {
        if ( try { $_->isa('Net::WAMP::X::NoSuchSubscription') } ) {
            $self->_create_and_send_ERROR(
                'UNSUBSCRIBE',
                $msg->get('Request'),
                {
                    net_wamp_message => $_->get_message(),
                },
                'wamp.error.no_such_subscription',
            );
        }
        else {
            local $@ = $_;
            die;
        }
    };

    return;
}

sub _send_UNSUBSCRIBED {
    my ($self, $req_id) = @_;

    return $self->_create_and_send_msg(
        'UNSUBSCRIBED',
        $req_id,
    );
}

sub _receive_PUBLISH {
    my ($self, $msg) = @_;

    my $publication;

    $self->_catch_exception(
        'PUBLISH',
        $msg->get('Request'),
        sub {
            try {
                $publication = $self->publish(
                    $self->{'_session'},
                    map { $msg->get($_) } qw(
                        Options
                        Topic
                        Arguments
                        ArgumentsKw
                    ),
                );

                if (Types::Serialiser::is_true($msg->get('Options')->{'acknowledge'})) {
                    $self->_send_PUBLISHED(
                        $msg->get('Request'),
                        $publication,
                    );
                }
            }
            catch {
                if ( try { $_->isa('Net::WAMP::X::BadURI') } ) {
                    $self->_create_and_send_ERROR(
                        'PUBLISH',
                        $msg->get('Request'),
                        {
                            net_wamp_message => $_->get_message(),
                        },
                        'wamp.error.invalid_uri',
                    );
                }
                else {
                    local $@ = $_;
                    warn;
                }
            };
        },
    );

    return $publication || ();
}

sub _send_PUBLISHED {
    my ($self, $req_id, $pub_id) = @_;

    return $self->_create_and_send_msg(
        'PUBLISHED',
        $req_id,
        $pub_id,
    );
}

sub _send_EVENT {
    my ($self, $sub_id, $pub_id, $details, @args) = @_;

    return $self->_create_and_send_msg(
        'EVENT',
        $sub_id,
        $pub_id,
        $details,
        @args,
    );
}

1;
