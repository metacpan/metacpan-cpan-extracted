use strict;
use warnings;

use Test::More tests => 11;
use AnyEvent;

use FindBin;
use lib $FindBin::Bin;

BEGIN { use_ok('TestArrayAsync'); }

my $obj = TestArrayAsync->new;

is_deeply([$obj->func1()], [1, 2]);
is_deeply([$obj->func2()], [2, 3, 4]);
is_deeply([$obj->func3(0)], []);
is_deeply([$obj->func3(1)], [1, 2]);
is_deeply([$obj->func3(2)], [2, 3, 4]);

my $cv = AE::cv;

$cv->begin;
$obj->func1_async()->cb(sub { is_deeply([shift->recv], [1, 2]); $cv->end; });
$cv->begin;
$obj->func2_async()->cb(sub { is_deeply([shift->recv], [2, 3, 4]); $cv->end; });
$cv->begin;
$obj->func3_async(0)->cb(sub { is_deeply([shift->recv], []); $cv->end; });
$cv->begin;
$obj->func3_async(1)->cb(sub { is_deeply([shift->recv], [1, 2]); $cv->end; });
$cv->begin;
$obj->func3_async(2)->cb(sub { is_deeply([shift->recv], [2, 3, 4]); $cv->end; });

$cv->recv;
