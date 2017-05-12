#!perl
use 5.014;
use Test::More tests => 2;
use Perl::SVCount;
my (@x, @y);
my $c = sv_count;
ok($c > 0, "sv_count returns positive value");
$c = sv_count; # refresh
push @x, "foo" for 1..100;
my $c2 = sv_count;
is($c2 - $c, 100);
