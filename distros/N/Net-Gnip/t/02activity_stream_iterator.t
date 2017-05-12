#!perl -w


use strict;
my $num = 5;
use Test::More;
use Net::Gnip::Activity;
plan tests => 9 + (2*$num);

use_ok('Net::Gnip::ActivityStream');


my $stream;
ok($stream = Net::Gnip::ActivityStream->new, "Created activity stream");
is(scalar($stream->activities), 0, "Got 0 activities");


my @activities;
my @values;
for (1..$num) {
    my $uid  = $_.time.$$.rand;
    push @activities, Net::Gnip::Activity->new('update', $uid);
    push @values, $uid;
}
ok($stream->activities(@activities), "Added an activity");
is(scalar($stream->activities), $num, "Got $num activity");
my ($tmp) = $stream->activities;
is($tmp->actor, $values[0], "Got the same type back");

my $count = 0;
while (my $a = $stream->next) {
    is($a->actor, $values[$count], "Got actor number ".++$count);
}
is($count, $num, "Got the correct count");
$count = 0;
ok($stream->reset, "Reset the stream");
while (my $a = $stream->next) {
    is($a->actor, $values[$count], "Got uid number ".++$count);
}
is($count, $num, "Got the correct count again");

