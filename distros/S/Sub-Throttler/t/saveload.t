use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;
use Test::Mock::Time;
use JSON::XS;
use Time::HiRes qw( sleep );

BEGIN {
    eval { Time::HiRes->import(qw( CLOCK_MONOTONIC clock_gettime )) };
    plan skip_all => 'Time::HiRes::clock_gettime(): unimplemented in this platform' if !exists &clock_gettime;
}

use Sub::Throttler::Limit;
use Sub::Throttler::Periodic::EV;
use Sub::Throttler::Rate::AnyEvent;


my ($throttle, $state);


# - Sub::Throttler::Limit

$throttle = Sub::Throttler::Limit->new(limit => 3);
ok $throttle->try_acquire('id1','key',3);
$state = $throttle->save();
$throttle = Sub::Throttler::Limit->load(decode_json(encode_json($state)));
is $throttle->limit, 3,
    'limit restored';
ok $throttle->try_acquire('id1','key',3),
    'acquired resources not restored';

wait_err();
$state->{version}++;
$throttle = Sub::Throttler::Limit->load($state);
like get_warn(), qr/future/ms;

$state = Sub::Throttler::Periodic::EV->new()->save();
throws_ok { Sub::Throttler::Limit->load($state) } qr/algorithm/;

# - Sub::Throttler::Periodic::EV

$throttle = Sub::Throttler::Periodic::EV->new(limit => 3, period => 0.1);
ok $throttle->try_acquire('id1','key',3);
throws_ok { $throttle->try_acquire('id1','key',100) } qr/already/;
$state = $throttle->save();
$throttle = Sub::Throttler::Periodic::EV->load(decode_json(encode_json($state)));
is $throttle->limit, 3,
    'limit restored';
is $throttle->period, 0.1,
    'period restored';
lives_ok { $throttle->try_acquire('id1','key',100) }
    'acquired ids not restored';
ok !$throttle->try_acquire('id1','key',3),
    'used resources restored';

sleep 0.1;
$throttle = Sub::Throttler::Periodic::EV->load($state);
ok $throttle->try_acquire('id1','key',3),
    'used resources not restored after period';

$state->{at} += 1000;
$throttle = Sub::Throttler::Periodic::EV->load($state);
ok !$throttle->try_acquire('id1','key',3),
    'used resources restored for time jump backward';

wait_err();
$state->{version}++;
$throttle = Sub::Throttler::Periodic::EV->load($state);
like get_warn(), qr/future/ms;

$state = Sub::Throttler::Limit->new()->save();
throws_ok { Sub::Throttler::Periodic::EV->load($state) } qr/algorithm/;

# - Sub::Throttler::Rate::AnyEvent

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 3, period => 0.2);
ok $throttle->try_acquire('id1','key',1);
throws_ok { $throttle->try_acquire('id1','key',100) } qr/already/;
sleep 0.1;
ok $throttle->try_acquire('id2','key',2);
$state = $throttle->save();
$throttle = Sub::Throttler::Rate::AnyEvent->load(decode_json(encode_json($state)));
is $throttle->limit, 3,
    'limit restored';
is $throttle->period, 0.2,
    'period restored';
lives_ok { $throttle->try_acquire('id1','key',100) }
    'acquired ids not restored';
ok !$throttle->try_acquire('id1','key',1),
    'used resources restored';
sleep 0.1;
ok !$throttle->try_acquire('id1','key',2);
ok $throttle->try_acquire('id1','key',1),
    'time when resource was acquired is restored';

sleep 0.1;
$throttle = Sub::Throttler::Rate::AnyEvent->load($state);
my $now = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC);
ok $throttle->try_acquire('id1','key',3),
    'used resources not restored after period';

$state->{at} += 1000;
for my $data (map {$_->{data}} values %{ $state->{used} }) {
    for (@{ $data }) {
        if ($_ != Sub::Throttler::Rate::rr::EMPTY()) {
            $_ += 1000;
        }
    }
}
$throttle = Sub::Throttler::Rate::AnyEvent->load($state);
ok !$throttle->try_acquire('id1','key',3),
    'used resources restored for time jump backward';

wait_err();
$state->{version}++;
$throttle = Sub::Throttler::Rate::AnyEvent->load($state);
like get_warn(), qr/future/ms;

$state = Sub::Throttler::Limit->new()->save();
throws_ok { Sub::Throttler::Rate::AnyEvent->load($state) } qr/algorithm/;


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

