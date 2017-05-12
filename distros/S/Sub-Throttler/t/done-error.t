use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;

use Sub::Throttler qw( :ALL );

use EV;

my @Result;

sub func {
    my $done = &throttle_me || return;
    my @p = @_;
    my $t;
    $t = EV::timer 0.01, 0, sub {
        $t = undef;
        push @Result, $p[0];
        for (1 .. $p[0]) {
            $done->();
        }
    };
    return;
}


@Result = ();
wait_err();
func(0);
EV::run EV::RUN_ONCE until @Result;
like get_warn(), qr/done->.*not called/ms,
    'missed $done->()';
is get_die(), q{};

@Result = ();
wait_err();
func(1);
EV::run EV::RUN_ONCE until @Result;
is get_warn(), q{},
    '$done->() called';
is get_die(), q{};

@Result = ();
wait_err();
func(2);
EV::run EV::RUN_ONCE until @Result;
like get_warn(), qr/done->.*already called/ms,
    '$done->() called twice';
like get_die(),  qr/done->.*already called/ms;

@Result = ();
wait_err();
func(0);
func(1);
func(2);
EV::run EV::RUN_ONCE until 3 == @Result;
like get_warn(), qr/done->.*not called/ms;
like get_warn(), qr/done->.*already called/ms;
like get_die(),  qr/done->.*already called/ms;


done_testing();


### Intercept warn/die/carp/croak messages
# wait_err();
# … test here …
# like get_warn(), qr/…/;
# like get_die(),  qr/…/;

my ($DieMsg, $WarnMsg);

sub wait_err {
    $DieMsg = $WarnMsg = q{};
    $::SIG{__WARN__} = sub { $WarnMsg .= $_[0] };
    $::SIG{__DIE__}  = sub { $DieMsg  .= $_[0] };
}

sub get_warn {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $WarnMsg;
}

sub get_die {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $DieMsg;
}

