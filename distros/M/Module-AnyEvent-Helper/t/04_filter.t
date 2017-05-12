use strict;
use warnings;

use Test::More tests => 11;
use AnyEvent;

use FindBin;
use lib $FindBin::Bin;

BEGIN { use_ok('TestAsync'); }

my $obj = TestAsync->new;

ok($obj->func1() == 1);
ok($obj->func2() == 2);
ok($obj->func3(0) == 0);
ok($obj->func3(1) == 1);
ok($obj->func3(2) == 2);

my $cv = AE::cv;

$cv->begin;
$obj->func1_async()->cb(sub { ok(shift->recv == 1); $cv->end; });
$cv->begin;
$obj->func2_async()->cb(sub { ok(shift->recv == 2); $cv->end; });
$cv->begin;
$obj->func3_async(0)->cb(sub { ok(shift->recv == 0); $cv->end; });
$cv->begin;
$obj->func3_async(1)->cb(sub { ok(shift->recv == 1); $cv->end; });
$cv->begin;
$obj->func3_async(2)->cb(sub { ok(shift->recv == 2); $cv->end; });

$cv->recv;
