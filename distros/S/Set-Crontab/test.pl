use strict;

use Test;
use vars qw($loaded);

BEGIN { plan tests => 11 }
END   { print "not ok 1\n" unless $loaded }

use Set::Crontab;
ok($loaded = 1);

my $r = [0..10];

ok(Set::Crontab->new("1,2,3,4,5,6", $r)->contains(6));
ok(Set::Crontab->new("1-10", $r)->contains(5));
ok(Set::Crontab->new("1-2,3-4,5-6,7-8,9-10", $r)->contains(7));
ok(Set::Crontab->new("1-4,5-10", $r)->contains(7));
ok(Set::Crontab->new("*/3", $r)->contains(6));

my $s = Set::Crontab->new("!3", $r);
ok(!$s->contains(3) && $s->contains(1));

$s = Set::Crontab->new(">3,<8", $r);
ok(!$s->contains(2) && $s->contains(6));

$s = Set::Crontab->new(">3,<8,!6", $r);
ok(!$s->contains(6) && $s->contains(7));

$s = Set::Crontab->new("*,!8", $r);
ok(!$s->contains(8) && $s->contains(3));

$s = Set::Crontab->new("1,*/2,!4", $r);
ok(!$s->contains(4) && $s->contains(2));

$s = Set::Crontab->new("45,15,30", [0..50]);
ok(join("", $s->list()) eq "153045");
