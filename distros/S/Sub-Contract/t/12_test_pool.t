#-------------------------------------------------------------------
#
#   $Id: 12_test_pool.t,v 1.4 2009/06/08 19:44:28 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Data::Dumper;
use Carp qw(croak);

package My::Class::One;

sub one { return 'one'; }

package My::Class::Two;

sub two { return 'two'; }

#
# main
#

package main;

use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 148;

    use_ok("Sub::Contract",'contract');
    use_ok("Sub::Contract::Pool",'get_contract_pool');
};

# a few contractors
sub foo { return 'foo'; }
sub bar { return 'bar'; }

# get the pool
my $pool = get_contract_pool();
ok(ref $pool eq 'Sub::Contract::Pool', "get_contract_pool returns a pool");

# check that has_contract validates arguments
eval { $pool->has_contract() };
ok($@ =~ /has_contract.. expects a fully qualified function name/, "has_contract croaks if no arguments");
eval { $pool->has_contract(1,2)};
ok($@ =~ /has_contract.. expects a fully qualified function name/, "has_contract croaks if 2 arguments");

#
# verify the content of the pool. should be as described by arguments
#

sub look_at_pool {
    my %expect = @_;

    if ($expect{size}) {
	my $size = $expect{size};
	is(scalar $pool->list_all_contracts(), $size, "pool contains $size contracts");
    }

    # the following contracts should never be in the pool
    my @impossible_names = ( 'bob::whatever',
			     'My::Class::One',
			     'My::Class',
			     'My::Class::Two::two::',
			     'my::class::two::two',
	);

    if ($expect{has_not}) {
	push @impossible_names, @{$expect{has_not}};
    }

    # check that the pool contains no contract for those fully qualified names
    foreach my $name (@impossible_names) {
	ok(!$pool->has_contract($name), "pool has no contract for contractor [$name]");
        is($pool->find_contract($name), undef, "and find_contract doesn't find [$name]");
    }

    if ($expect{has}) {
	foreach my $name (@{$expect{has}}) {
	    # check that has_contract agrees that contract is in pool
	    ok($pool->has_contract($name), "pool has contract for contractor [$name]");

	    my $c = $pool->find_contract($name);
	    is(ref $c, "Sub::Contract",  "find_contract returns a contract");
	    is($c->contractor, $name,  "find_contract returns the right contract");

	    # check that this contract really is in the pool
	    my $found = 0;
	    foreach my $contract ($pool->list_all_contracts()) {
		$found++ if ($contract->contractor eq $name);
	    }

	    is($found, 1, "this contract really is in the pool");
	}
    }

    # test that the names of subroutine never matches
    eval { $pool->has_contract('foo') };
    ok( $@ =~ /method has_contract.. expects a fully qualified function name/, "has_contract croaks on name 'foo'");

    eval { $pool->find_contract('foo') };
    ok( $@ =~ /method find_contract.. expects a fully qualified function name/, "find_contract croaks on name 'foo'");
}

#
# verify the content of the pool after adding contracts one at a time
#

# initialy, the pool should be empty
look_at_pool(size    => 0,
	     has_not => [ 'My::Class::One::one', 'My::Class::Two::two', 'main::foo', 'main::bar' ],
    );

# add 1 contract
contract('My::Class::One::one')->in->out->enable;
look_at_pool(size    => 1,
	     has_not => [ 'My::Class::Two::two', 'main::foo', 'main::bar' ],
	     has     => [ 'My::Class::One::one' ],
);

contract('My::Class::Two::two')->in->out->enable;
look_at_pool(size => 2,
	     has_not => [ 'main::foo', 'main::bar' ],
	     has     => [ 'My::Class::Two::two', 'My::Class::One::one' ],
);

contract('main::foo')->in->out->enable;
look_at_pool(size => 3,
	     has_not => [ 'main::bar' ],
	     has     => [ 'main::foo', 'My::Class::Two::two', 'My::Class::One::one' ],
);

contract('main::bar')->in->out->enable;
look_at_pool(size => 4,
	     has     => [ 'main::bar', 'main::foo', 'My::Class::Two::two', 'My::Class::One::one' ],
);

#
# test searching for contracts
#

# test find_contracts_matching croak

my @tests = (
    'foo'         => 0, [ ],
    '.*::foo'     => 1, [ 'main::foo' ],
    '::foo'       => 0, [ ],
    'main::foo'   => 1, [ 'main::foo' ],
    'main::.*'    => 2, [ 'main::foo', 'main::bar' ],
    'main'        => 0, [ ],
    'main::z'     => 0, [ ],
    '.*::.*'      => 4, [ 'main::foo', 'main::bar', 'My::Class::Two::two', 'My::Class::One::one' ],
    '.*(two|foo)' => 2, [ 'main::foo', 'My::Class::Two::two' ],
    '.*o.*'         => 3, [ 'main::foo', 'My::Class::Two::two', 'My::Class::One::one' ],

    # TODO: add more matches?
    );

while (@tests) {
    my $match = shift @tests;
    my $size  = shift @tests;
    my $names = shift @tests;

    my @res = $pool->find_contracts_matching( $match );
    is(scalar @res, $size, "find_contract_matching($match) returns $size hits");

    if (scalar @res) {
	my %found_names;
	map { $found_names{$_->contractor} = 1 } @res;

	my $ok = 1;
	foreach my $contract (@res) {
	    $ok = 0 if (!exists $found_names{$contract->contractor});
	}
	is($ok,1,"found exactly the expected contracts");
    }
}

#
# enable/disable contracts selectively
#

sub count_enabled_contracts {
    my $count_on = 0;
    foreach my $contract ($pool->list_all_contracts) {
	$count_on++ if ($contract->is_enabled);
    }
    return $count_on;
}

# by default, all contracts should be enabled
is(count_enabled_contracts, 4, "all contracts enabled by default");

$pool->disable_all_contracts;
is(count_enabled_contracts, 0, "test disable_all_contracts");

$pool->enable_all_contracts;
is(count_enabled_contracts, 4, "test enable_all_contracts");

# TODO: test disable/enable_..._matching
