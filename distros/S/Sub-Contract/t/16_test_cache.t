#-------------------------------------------------------------------
#
#   $Id: 16_test_cache.t,v 1.8 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    $ENV{PERL5SUBCONTRACTSTATS} = 1;

    use check_requirements;
    plan tests => 64;

    use_ok("Sub::Contract",'contract');
    use_ok("Sub::Contract::Memoizer");
};

my @results;

sub foo_array {
    return @results;
}

my $results;

sub foo_scalar {
    return $results;
}

my $c1 = contract('foo_array')->cache->enable;
my $c2 = contract('foo_scalar')->cache->enable;

my $obj1 = bless({ a=> 1},"oops");

my @tests = (
	     # @results,  foo args,  foo results

	     # caching various structs in scalar contexts
	     0, 123, ["abc"], 123,
	     0, 456, ["abc"], 123,
	     0, 456, ["bcd"], 456,
	     0, 3, ["bcd"], 456,
	     0, 4, ["bcd"], 456,

	     0, "bob", [1,2,3], "bob",
	     0, "123", [1,2,3], "bob",
	     0, "789", [1,2,3], "bob",

	     0, $obj1,     [1,2],   $obj1,
	     0, undef,     [1,2],   $obj1,

	     0, [1,2,[3,4]],            ["bob"], [1,2,[3,4]],
	     0, undef,                  ["bob"], [1,2,[3,4]],
	     0, "o",                    ["bab"], "o",

	     # caching various structs in array contexts
	     1, [1,2,3], ["abc"], [1,2,3],
	     1, [],      ["abc"], [1,2,3],
	     1, [],      ["abc"], [1,2,3],
	     1, [],      ["bcd"], [],

	     1, [ $obj1 ], [1,2],   [ $obj1 ],
	     1, [ undef ], [1,2],   [ $obj1 ],

	     1, [1,2,[3,4]],  ["bob"], [1,2,[3,4]],
	     1, [],           ["bob"], [1,2,[3,4]],

	     );

while (@tests) {
    my $wantarray = shift @tests;
    my $res  = shift @tests;
    my $args = shift @tests;
    my $want = shift @tests;

    if ($wantarray) {
	@results = @{$res};
	my @a = foo_array(@$args);
	is_deeply(\@a,$want,"\@{foo(".join(",",@$args).")} = (".join(",",@$want).")");

	@results = ();
	@a = foo_array(@$args);
	is_deeply(\@a,$want,"same but from cache");

    } else {
	$results = $res;
	my $a = foo_scalar(@$args);
	is_deeply($a,$want,"\${foo(".join(",",@$args).")} = ".$want);

	$results = undef;
	$a = foo_scalar(@$args);
	is_deeply($a,$want,"same but from cache");
    }
}

# key contain references
eval { my $a = foo_scalar({1,2,3,4},3); };
ok($@ =~ /cannot memoize result of main::foo_scalar when input arguments contain references/, "contract fail if args contain references");

# wrong context
eval { foo_scalar(3,3); };
ok($@ =~ /calling memoized subroutine main::foo_scalar in void context/, "contract fail when void context");

# test an early bug, in which different subs shared the same cache
contract("pif")->cache->enable;
contract("paf")->cache->enable;

sub pif {
    return (a => 1, b => 2);
}

sub paf {
    return (a => "boum");
}

my %r1 = pif(1,2,3);
is_deeply(\%r1, {a => 1, b => 2}, "calling pif once");
%r1 = pif(1,2,3);
is_deeply(\%r1, {a => 1, b => 2}, "calling pif twice");

%r1 = paf(1,2,3);
is_deeply(\%r1, {a => "boum"}, "calling paf. got paf's answer and not pif's");

# test cache versus context
contract("bim")->cache->enable;
my @ret;
sub bim { return @ret; }

@ret = ("abc","123");

my @res = bim();
is_deeply(\@res,["abc","123"],"first get, array context");
@ret = (1,2,3,4);
@res = bim();
is_deeply(\@res,["abc","123"],"second get, array context");

my $res = bim();
is($res,4,"third get, scalar context: yield new value");

# test caching undef
contract("returnsundef")->cache->enable;
my $ret = undef;
sub returnsundef { return $ret; }

is(returnsundef(1,2), undef, "storing undef in cache");
$ret = 1234;
is(returnsundef(1,2), undef, "getting undef from cache");

# test hitting cache max size
contract("hitmehard")->cache(size => 10)->enable;
sub hitmehard { return $ret; }

$ret = 42;
# fill cache
for (my $i=1; $i<=10; $i++) {
    my $r = hitmehard($i);
}
$ret = 24;
is(hitmehard(1),42,"cache not cleared yet");

# double check
ok(Sub::Contract::Memoizer::_get_cache_stats_report =~ /total max size reached: 0/mg, "stats report agrees");

# clear cache by hitting max limit
{   my $r = hitmehard(11); }

is(hitmehard(1),24,"cache cleared upon hitting max size");

# double check
ok(Sub::Contract::Memoizer::_get_cache_stats_report =~ /total max size reached: 1/mg, "stats report agrees");

# test the stats report
my $report = Sub::Contract::Memoizer::_get_cache_stats_report;
ok($report =~ /main::bim\s+:\s+33\.3 \% hits .calls: 3, hits: 1/mg, "stats report ok for main::bim");
ok($report =~ /main::foo_scalar\s+:\s+76\.9 \% hits .calls: 26, hits: 20/mg, "stats report ok for main::foo_cache");
ok($report =~ /number of caches: 7/mg, "stats report ok for number of cache");
ok($report =~ /total calls: 63/mg, "stats report ok for total calls");
ok($report =~ /total hits: 36/mg, "stats report ok for total hits");
ok($report =~ /total max size reached: 1/mg, "stats report ok for total max size reached");
