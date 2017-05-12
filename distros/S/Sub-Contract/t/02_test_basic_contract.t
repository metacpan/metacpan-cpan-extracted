#-------------------------------------------------------------------
#
#   $Id: 02_test_basic_contract.t,v 1.6 2009/06/01 20:43:06 erwan_lemonnier Exp $
#

#-------------------------------------------------------------------
#
#   test package
#

package My::Test;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Sub::Contract qw(contract);

sub foo1 { return 'test'; };
sub foo2 { return 'test'; };

sub get_contract {
    return contract('foo1');
}

#-------------------------------------------------------------------
#
#   main tests
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    use check_requirements;
    plan tests => 30;

    use_ok("Sub::Contract",'contract');
    use_ok("Sub::Contract::Pool",'get_contract_pool');
};

my $c1 = contract('foo1');

my $value;
sub foo1 { return $value; }
sub foo2 { return $value; }
sub foo3 { return $value; }
sub foo4 { return $value; }
sub foo7 { return $value; }

# test that the contract pool now contains all those contracts
my $pool = get_contract_pool();
is(ref $pool, 'Sub::Contract::Pool', "check got a contract pool");

my @all = $pool->list_all_contracts();
is(scalar @all, 1, "one contract registered");
is_deeply($all[0], $c1, "that's the expected contract");

# test private attributes
my $expect = {
    is_memoized => 0,
    is_enabled => 0,
    contractor => 'main::foo1',
    pre => undef,
    post => undef,
    in => undef,
    out => undef,
    invariant => undef,
};

is(ref $c1->{contractor_cref}, "CODE", "contract contains cref");
delete $c1->{contractor_cref};
is_deeply($c1, $expect, "check contract structure");

# check alternative constructors
$c1->{contractor} = 'main::foo2';
my $c2 = new Sub::Contract('foo2');
delete $c2->{contractor_cref};
is_deeply($c1,$c2,"new Sub::Contract() returns same as contract()");

$c1->{contractor} = 'main::foo3';
my $c3 = Sub::Contract->new('foo3');
delete $c3->{contractor_cref};
is_deeply($c1,$c3,"Sub::Contract->new() returns same as contract()");

$c1->{contractor} = 'main::foo4';
my $c4 = Sub::Contract->new('foo4', caller => 'main');
delete $c4->{contractor_cref};
is_deeply($c1,$c4,"Sub::Contract->new() returns same as contract() when caller specified");

$c1->{contractor} = 'My::Test::foo1';
my $c5 = My::Test::get_contract;
delete $c5->{contractor_cref};
is_deeply($c1,$c5,"same when called from another package than main::");

$c1->{contractor} = 'My::Test::foo2';
my $c6 = Sub::Contract->new('foo2', caller => 'My::Test');
delete $c6->{contractor_cref};
is_deeply($c1,$c6,"same as above, but set by caller =>");


$c1->{contractor} = "main::foo";

# testing contractor
is($c1->contractor,"main::foo","test contractor");
is($c2->contractor,"main::foo2","test contractor");
is($c3->contractor,"main::foo3","test contractor");
is($c4->contractor,"main::foo4","test contractor");

my $c7 = contract('foo7');

# check that whatever happened didn't affect the contractor
$value = "bob";
is(foo7(123),"bob","foo7 returns bob before contract enabled");

# now enabling contract
$c7->enable();
is(foo7(456),"bob","foo7 returns bob after contract enabled");

# now disabling contract
$c7->disable();
is(foo7(789),"bob","foo7 returns bob after contract disabled");

# how is the pool now?
@all = $pool->list_all_contracts();
is(scalar @all, 7, "pool now contains 6 contracts");

# test croaks in new()
eval { Sub::Contract->new('foo7') };
ok( $@ =~ /trying to contract function \[main::foo7\] twice at .*02_test_basic_contract.t/, "croak when contracting a sub twice");

eval { Sub::Contract->new() };
ok( $@ =~ /new\(\) expects a subroutine name as first argument at .*02_test_basic_contract.t/, "croak when undefined sub in new()");

eval { Sub::Contract->new('blah',1,2) };
ok( $@ =~ /new\(\) got unknown arguments:/, "croak when unknown arguments in new()");

# croak if unknown contractor sub
eval { contract('foobar') };
ok( $@ =~ /Can.t find subroutine named 'main::foobar' at .*02_test_basic_contract.t/, "croak when contracting unknown sub");

eval { contract('MyTest::foobar') };
ok( $@ =~ /Can.t find subroutine named 'MyTest::foobar' at .*02_test_basic_contract.t/, "croak when contracting unknown sub");

eval { Sub::Contract->new('MyTest::foobar', caller => 'MyTest') };
ok( $@ =~ /Can.t find subroutine named 'MyTest::foobar' at .*02_test_basic_contract.t/, "croak when contracting unknown sub");

eval { Sub::Contract->new('foobar', caller => 'MyTest') };
ok( $@ =~ /Can.t find subroutine named 'MyTest::foobar' at .*02_test_basic_contract.t/, "croak when contracting unknown sub");

# test croaks in contract()
eval { contract() };
ok( $@ =~ /contract\(\) expects only one argument, a subroutine name at .*02_test_basic_contract.t/, "contract() croaks on no arguments");

eval { contract(1,2) };
ok( $@ =~ /contract\(\) expects only one argument, a subroutine name at .*02_test_basic_contract.t/, "contract() croaks on too many arguments");

eval { contract(undef) };
ok( $@ =~ /contract\(\) expects only one argument, a subroutine name at .*02_test_basic_contract.t/, "contract() croaks on undefined argument");

# TODO: test more croaks?



