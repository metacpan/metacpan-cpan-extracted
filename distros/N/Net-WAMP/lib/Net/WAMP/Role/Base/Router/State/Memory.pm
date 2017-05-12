package Net::WAMP::Role::Base::Router::State::Memory;

#----------------------------------------------------------------------
# The default setup involves storing all of the router state in memory
# and depending on a non-forking server.
#
# This abstraction should allow using an arbitrary storage backend
# and should accommodate a forking server.
#
# At the same time, what would the advantage of a forking server be?
# Anyway, if nothing else it’s a nice abstraction. So, here’s this.
#----------------------------------------------------------------------

use strict;
use warnings;

use parent qw( Net::WAMP::Role::Base::Router::State );

sub new {
    return bless {}, shift;
}

#----------------------------------------------------------------------

#sub realm_property_exists {
#    my ($self, $session, $property) = @_;
#
#    $self->_verify_known_session($session);
#
#    my $realm = $self->{'_session_realm'}{$session};
#
#    return exists($self->{'_realm_data'}{$realm}{$property}) ? 1 : 0;
#}

sub get_realm_property {
    my ($self, $session, $property) = @_;

    $self->_verify_known_session($session);

    my $realm = $self->{'_session_realm'}{$session};

    return $self->{'_realm_data'}{$realm}{$property};
}

sub set_realm_property {
    my ($self, $session, $key, $value) = @_;

    $self->_verify_known_session($session);

    my $realm = $self->{'_session_realm'}{$session};

    $self->{'_realm_data'}{$realm}{$key} = $value;

    $self->_mark_for_removal_with_session( $session, $key );

    return $self;
}

sub unset_realm_property {
    my ($self, $session, $key) = @_;

    $self->_verify_known_session($session);

    my $realm = $self->{'_session_realm'}{$session};

    #We don’t un-mark for removal since it will make no difference.

    return $self->{'_realm_data'}{$realm}{$key};
}

#----------------------------------------------------------------------
# XXX These “deep” methods seem a real kludge … but better than
# polymorphic?

#sub get_realm_deep_property {
#    my ($self, $session, $property) = @_;
#
#    my $realm = $self->_check_session_and_get_realm($session);
#
#    my ($hr, $key) = _resolve_deep_property(
#        $self->{'_realm_data'}{$realm},
#        $property,
#    );
#
#    return $hr->{$key};
#}

sub set_realm_deep_property {
    my ($self, $session, $property, $value) = @_;

    my $realm = $self->_check_session_and_get_realm($session);

    my ($hr, $key) = _resolve_deep_property(
        $self->{'_realm_data'}{$realm},
        $property,
    );

    $hr->{$key} = $value;

    $self->_mark_for_removal_with_session( $session, $property );

    return $self;
}

sub unset_realm_deep_property {
    my ($self, $session, $property) = @_;

    my $realm = $self->_check_session_and_get_realm($session);

    #We don’t un-mark for removal since it will make no difference.

    my ($hr, $key) = _resolve_deep_property(
        $self->{'_realm_data'}{$realm},
        $property,
    );

    return delete $hr->{$key};
}

sub _resolve_deep_property {
    my ($hr, $prop_ar) = @_;

    my @prop = @$prop_ar;

    my $final_key = pop @prop;
    $hr = ($hr->{shift @prop} ||= {}) while @prop;

    return ($hr, $final_key);
}

#----------------------------------------------------------------------
#session determines a realm, but not vice-versa

sub add_session {
    my ($self, $session, $realm) = @_;

    if ($self->{'_session_data'}{$session}) {
        die "State $self already has IO $session!";
    }

    $self->{'_session_data'}{$session} = {};
    $self->{'_session_realm'}{$session} = $realm;

    return $self;
}

sub get_realm_for_session {
    my ($self, $session) = @_;

    $self->_verify_known_session($session);

    return $self->{'_session_realm'}{$session};
}

sub session_exists {
    my ($self, $session) = @_;

    return exists($self->{'_session_data'}{$session}) ? 1 : 0;
}

sub get_session_property {
    my ($self, $session, $key) = @_;

    $self->_verify_known_session($session);

    return $self->{'_session_data'}{$session}{$key};
}

sub set_session_property {
    my ($self, $session, $key, $value) = @_;

    $self->_verify_known_session($session);

    $self->{'_session_data'}{$session}{$key} = $value;

    return $self;
}

sub unset_session_property {
    my ($self, $session, $key) = @_;

    $self->_verify_known_session($session);

    return delete $self->{'_session_data'}{$session}{$key};
}

sub forget_session {
    my ($self, $session) = @_;

    #Be willing to accept no-op forgets.
    #$self->_verify_known_session($session);

    my $realm = delete $self->{'_session_realm'}{$session};
    delete $self->{'_session_data'}{$session};

    $self->_do_removal_with_session($session, $realm);

    return $self;
}

#----------------------------------------------------------------------

sub _check_session_and_get_realm {
    my ($self, $session) = @_;

    $self->_verify_known_session($session);

    return $self->{'_session_realm'}{$session};
}

sub _verify_known_session {
    my ($self, $session) = @_;

    if (!$self->{'_session_data'}{$session}) {
        die "IO object $session isn’t in state $self!";
    }

    return;
}

sub _mark_for_removal_with_session {
    my ($self, $session, $to_remv) = @_;

    push @{ $self->{'_remove_with_session'}{$session} }, $to_remv;

    return $self;
}

sub _do_removal_with_session {
    my ($self, $session, $realm) = @_;

    if (my $remv_ar = delete $self->{'_remove_with_session'}{$session}) {
        for my $remv (@$remv_ar) {
            if (ref $remv) {
                my ($hr, $key) = _resolve_deep_property(
                    $self->{'_realm_data'}{$realm},
                    $remv,
                );

                delete $hr->{$key};
            }
            else {
                delete $self->{'_realm_data'}{$realm}{$remv};
            }
        }
    }

    return;
}

1;
