package Pcore::Core::Exception;

use Pcore -result, -export => {    #
    DEFAULT => [qw[croak cluck]],
};
use Carp qw[];
use Pcore::Core::Exception::Object;

our $IGNORE_ERRORS = 1;            # do not write errors to error log channel by default

# needed to properly destruct TEMP_DIR
$SIG->{INT} = AE::signal INT => \&SIGINT;

# required for properly remove TEMP_DIR
$SIG->{TERM} = AE::signal TERM => \&SIGTERM;

$SIG{__DIE__} = \&SIGDIE;          ## no critic qw[Variables::RequireLocalizedPunctuationVars]

$SIG{__WARN__} = \&SIGWARN;        ## no critic qw[Variables::RequireLocalizedPunctuationVars]

# we don't need stacktrace from Error::TypeTiny exceptions
$Error::TypeTiny::StackTrace = 0;

$Coro::State::DIEHOOK = sub {

    # not in eval
    if ( !$^S ) {
        my $e = Pcore::Core::Exception::Object->new( $_[0], level => 'ERROR', skip_frames => 1, with_trace => 1 );

        {
            local $@;

            eval { $e->sendlog('FATAL') };
        }

        $Coro::current->cancel( result 500 );
    }

    return;
};

$Coro::State::WARNHOOK = sub {
    my $e = Pcore::Core::Exception::Object->new( $_[0], level => 'ERROR', skip_frames => 1, with_trace => 1 );

    {
        local $@;

        eval { $e->sendlog('FATAL') };
    }

    return;
};

# redefine Carp::longmess, Carp::shotmess, disable stack trace
{
    no warnings qw[redefine];

    *Carp::longmess = *Carp::shortmess = sub {
        if ( defined $_[0] ) {
            return $_[0];
        }
        else {
            return q[];
        }
    };
}

sub SIGINT {
    exit 128 + 2;
}

sub SIGTERM {
    exit 128 + 15;
}

# SIGNALS
sub SIGDIE {
    my $e = Pcore::Core::Exception::Object->new( $_[0], level => 'ERROR', skip_frames => 1, with_trace => 1 );

    # error in AE callback
    if ( $^S && $e->{is_ae_cb_error} ) {
        {
            local $@;

            eval { $e->sendlog('FATAL') };
        }

        return CORE::die $e;    # set $@ to $e
    }

    # ERROR, !defined $^S - parsing module, eval, or main program, true - executing in eval
    elsif ( !defined $^S || $^S ) {
        if ( !$IGNORE_ERRORS ) {
            local $@;

            eval { $e->sendlog('ERROR') };
        }

        return CORE::die $e;    # set $@ to $e
    }

    # FATAL
    else {
        {
            local $@;

            eval { $e->sendlog('FATAL') };
        }

        exit $e->exit_code;
    }
}

sub SIGWARN {

    # skip AE callback error warning
    return if $_[0] =~ /\AEV: error in callback/sm;

    my $e = Pcore::Core::Exception::Object->new( $_[0], level => 'WARN', skip_frames => 1, with_trace => 1 );

    {
        local $@;

        $e->sendlog('WARN');
    }

    return;    # skip standard warn behaviour
}

# die without trace
sub croak {
    my $msg;

    if (@_) {
        if ( @_ > 1 ) {
            $msg = join q[], @_;
        }
        else {
            $msg = $_[0];
        }
    }
    elsif ($@) {
        $msg = $@ . ' ...propagated';
    }
    else {
        $msg = 'Died';
    }

    my $e = Pcore::Core::Exception::Object->new( $msg, level => 'ERROR', skip_frames => 1, with_trace => 0 );

    return CORE::die $e;
}

# warn without trace
sub cluck {
    my $msg;

    if (@_) {
        if ( @_ > 1 ) {
            $msg = join q[], @_;
        }
        else {
            $msg = $_[0];
        }
    }
    elsif ($@) {
        $msg = $@ . ' ...caught';
    }
    else {
        $msg = q[Warning: something's wrong];
    }

    my $e = Pcore::Core::Exception::Object->new( $msg, level => 'WARN', skip_frames => 1, with_trace => 0 );

    return CORE::warn $e;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 31, 46, 83, 94, 105, | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |      |  122                 |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 33, 48, 85, 96, 107  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 Pcore::Core::Exception

Pharaoh::Core::Sig - signals management for Pharaoh::Core.

This package is part of Pharaoh::Core.

=head1 EXPORTS

=head2 CORE::GLOBAL::exit

Common exit() family functions behaviour:

=over

=item * threads->exit() and CORE::exit() is unhandled in threads and perform exit according to threads->set_thread_exit_only;

=item * CORE::exit() is unhandled;

=back

=head1 SIGNALS

=head2 SIGDIE

Standart $SIG{__DIE__} exceptions handler. Use following code to redefined callback:

    local $SIG{__DIE__};        # Redefine handler locally, no callback defined, $SIG{__DIE__} will be ignored
    local $SIG{__DIE__} = sub { # Ditto with callback defined
            ...do something...
        };

=over

=item * C<$SIG{__DIE__}> called from eval block produce ERROR log with stack trace and returns;

=item * C<$SIG{__DIE__}> called from NOT eval block produce FATAL log with stack trace and exit from process / thread;

=item * C<__ALRM__> exception from eval ignored;

=item * C<__ALRM__> exception from NOT eval block produce FATAL exception;

=item * C<__EXIT__> exception is ignored totally and can be processed in your code. See CORE::GLOBAL::exit for example;

=item * Calling die() in $SIG{__DIE__} will overwrite $@ and exit $SIG{__DIE__} immidiately;

=item * Overriding die will only catch actual calls to die, not run-time errors;

=back

=head2 SIGWARN

Standart $SIG{__WARN__} handler. Produce standart log event on WARN level with stack backtace. To avoid call use following in your code:

    local $SIG{__WARN__} = sub { };    # Redefine callback locally
    local $SIG{__WARN__} = undef;      # Restore standart behaviour in current block

=head2 SIGALRM

Standart $SIG{ALRM} handler. Produce C<__ALRM__> exception. To redefine callback use following in your code:

    local $SIG{ALRM} = sub { };    # Redefine callback locally

or use this alarm - safe code:

    my $orig_alarm = 0;
    eval{
        $orig_alarm = alarm 5;    # Store previous alarm() timer internally
        ...some code here...
    };
    alarm $orig_alarm;            # Restore previous timer

    if($@ =~ /^__ALRM__/){
        ...do something on alarm...
    }

NOTES

=over

=item * If $SIG{ALRM} not defined - process will killed on alarm. SIG{__DIE__} don't handle alarm exception;

=item * Alarm - safe code must restore previous alarm timer at the end of execution. We can't control bad written code in other modules, so be ready that you alarm timers will not work if you use not alarm - safe modules;

=item * alarm() works on MSWin and in threads as expected;

=item * You must remove alarm timer immidiately after end of eval block (not in block), because if evaluated code will die - eval block will be broken and your alarm will not be removed;

=item * alarm() call on MSWin didn't return amount of time remaining for previous timer. So chained timers on MSWin NOT WORKED.

=back

=cut
