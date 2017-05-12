use strict;
use warnings;

use Test::More (tests => 34);

use Spike::Site::Router::Route;

my $r = Spike::Site::Router::Route->new;

ok($r->route == $r);
ok($r->route('///') == $r);

my $r1 = $r->route('l1/*/l3/#n/l5');

my $r2 = $r ->route('l1');
my $r3 = $r2->route('*');
my $r4 = $r3->route('l3');
my $r5 = $r4->route('#n');
my $r6 = $r5->route('l5');

ok($r1 == $r6);

ok($r->find('l1') == $r2);
ok(!$r->find('l1x'));
ok(!$r->find('xl1'));

ok($r->find('l1/smth') == $r3);

ok($r->find('l1/smth/l3') == $r4);
ok(!$r->find('l1/smth/l3x'));
ok(!$r->find('l1/smth/xl3'));

ok($r->find('l1/smth/l3/smth') == $r5);

ok($r->find('l1/smth/l3/smth/l5') == $r6);
ok(!$r->find('l1/smth/l3/smth/l5x'));
ok(!$r->find('l1/smth/l3/smth/xl5'));

ok(!$r->find('l1/smth/l3/smth/l5/smth'));

my $r7 = $r->route('ll1/#n1/ll3/#n2/ll5/#n3/ll7/#n4/ll9' => [qw(t1)], qr!t2!, sub { $_ eq 't3' });

ok($r->find('ll1/t1'));

ok(!$r->find('ll1/t1x'));
ok(!$r->find('ll1/xt1'));
ok(!$r->find('ll1/t2'));
ok(!$r->find('ll1/t3'));
ok(!$r->find('ll1/t1/xx'));

ok($r->find('ll1/t1/ll3/t2'));

ok(!$r->find('ll1/t1/ll3/t2x'));
ok(!$r->find('ll1/t1/ll3/xt2'));
ok(!$r->find('ll1/t1/ll3/t1'));
ok(!$r->find('ll1/t1/ll3/t3'));
ok(!$r->find('ll1/t1/ll3/t2/xx'));

ok($r->find('ll1/t1/ll3/t2/ll5/t3'));

ok(!$r->find('ll1/t1/ll3/t2/ll5/t3x'));
ok(!$r->find('ll1/t1/ll3/t2/ll5/xt3'));
ok(!$r->find('ll1/t1/ll3/t2/ll5/t1'));
ok(!$r->find('ll1/t1/ll3/t2/ll5/t2'));
ok(!$r->find('ll1/t1/ll3/t2/ll5/t3/xx'));

ok($r->find('ll1/t1/ll3/t2/ll5/t3/ll7/tt/ll9') == $r7);
