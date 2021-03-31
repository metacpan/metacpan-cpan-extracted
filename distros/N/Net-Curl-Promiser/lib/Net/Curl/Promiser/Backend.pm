package Net::Curl::Promiser::Backend;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::LeakDetector';

use Net::Curl::Multi ();

use constant PROMISE_CLASS => 'Promise::ES6';

sub new {
    return bless {
        ignore_leaks => $Net::Curl::Promiser::IGNORE_MEMORY_LEAKS,
        to_fail => {},
    }, shift;
}

sub cancel_handle {
    my ($self, $easy, $multi) = @_;

    return $self->_fail_or_cancel($easy, undef, $multi);
}

sub fail_handle {
    my ($self, $easy, $reason, $multi) = @_;

    return $self->_fail_or_cancel($easy, \$reason, $multi);
}

sub _fail_or_cancel {
    my ($self, $easy, $reason_sr, $multi) = @_;

    $self->_is_pending($easy) or die "Cannot fail non-pending request!";

    $self->{'to_fail'}{$easy} = [ $easy, $reason_sr ];

    $self->_clear_failed($multi);

    return $self;
}

sub add_handle {
    my ($self, $easy, $multi) = @_;

    if ($self->_is_pending($easy)) {
        require Carp;
        Carp::croak("Attempted to re-add in-progress handle");
    }

    $multi->add_handle($easy);

    my $env_engine = $ENV{'NET_CURL_PROMISER_PROMISE_ENGINE'} || q<>;

    my $promise;

    if ($env_engine eq 'Promise::XS') {
        require Promise::XS;

        my $deferred = Promise::XS::deferred();
        $self->{'deferred'}{$easy} = $deferred;
        $promise = $deferred->promise();
    }
    elsif ($env_engine) {
        die "bad promise engine: [$env_engine]";
    }
    else {
        $self->PROMISE_CLASS()->can('new') or do {
            my $class = $self->PROMISE_CLASS();

            local $@;
            die if !eval "require $class";
        };

        $promise = $self->PROMISE_CLASS()->new( sub {
            $self->{'callbacks'}{$easy} = \@_;
        } );
    }

    return $promise;
}

sub process {
    my ($self, $multi, $fd_action_args_ar) = @_;

    my $fd_action_hr = $self->_GET_FD_ACTION($fd_action_args_ar);

    if (%$fd_action_hr) {
        for my $fd (keys %$fd_action_hr) {
            $multi->socket_action( $fd, $fd_action_hr->{$fd} );
        }
    }
    else {
        $multi->socket_action( Net::Curl::Multi::CURL_SOCKET_TIMEOUT() );
    }

    $self->process_pending( $multi );

    return;
}

sub process_pending {
    my ($self, $multi) = @_;

    $self->_clear_failed($multi);

    while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {

        if ($msg != Net::Curl::Multi::CURLMSG_DONE()) {
            die "Unrecognized info_read() message: [$msg]";
        }

        $self->_finish_handle(
            $easy,
            $multi,
            ($result == 0) ? ( 0 => $easy ) : ( 1 => \$result ),
        );
    }

    return;
}

sub get_timeout {
    my ($self, $multi) = @_;

    return %{ $self->{'to_fail'} } ? 0 : $multi->timeout();
}

sub time_out {
    my ($self, $multi) = @_;

    my $is_active = $multi->socket_action( Net::Curl::Multi::CURL_SOCKET_TIMEOUT() );

    $self->process_pending($multi);

    return $is_active;
}

#----------------------------------------------------------------------

sub _GET_FD_ACTION {
    return +{ @{ $_[1] } };
}

sub _is_pending {
    my ($self, $easy) = @_;

    return $self->{'callbacks'}{$easy} || $self->{'deferred'}{$easy};
}

sub _finish_handle {
    my ($self, $easy, $multi, $cb_idx, $payload) = @_;

    # If $cb_idx == 0, then $payload is a promise resolution.
    # If $cb_idx == 1, then $payload is either:
    #   undef       - request canceled
    #   scalar ref  - promise rejection

    my $err = $@;

    # Don’t depend on the caller to report failures.
    # (AnyEvent, for example, blackholes them.)
    warn if !eval {
        delete $self->{'to_fail'}{$easy};

        # This has to precede the callbacks so that $easy can be added back
        # into $self->{'multi'} within the callback.
        $multi->remove_handle($easy);

        if ( my $cb_ar = delete $self->{'callbacks'}{$easy} ) {
            $cb_ar->[$cb_idx]->($cb_idx ? $$payload : $payload) if !$cb_idx || $payload;
        }
        elsif ( my $deferred = delete $self->{'deferred'}{$easy} ) {
            if ($cb_idx) {
                $deferred->reject($$payload) if $payload;
            }
            else {
                $deferred->resolve($payload);
            }
        }
        else {

            # This shouldn’t happen, but just in case:
            require Data::Dumper;
            print STDERR Data::Dumper::Dumper( ORPHAN => $easy => $payload );
        }

        1;
    };

    $@ = $err;

    return;
}

#----------------------------------------------------------------------

sub _clear_failed {
    my ($self, $multi) = @_;

    for my $val_ar ( values %{ $self->{'to_fail'} } ) {
        my ($easy, $reason_sr) = @$val_ar;
        $self->_finish_handle( $easy, $multi, 1, $reason_sr );
    }

    %{ $self->{'to_fail'} } = ();

    return;
}

1;
