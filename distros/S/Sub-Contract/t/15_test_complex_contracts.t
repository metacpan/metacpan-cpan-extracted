#-------------------------------------------------------------------
#
#   $Id: 15_test_complex_contracts.t,v 1.4 2008/06/17 11:31:42 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {

    use check_requirements;
    plan tests => 29;

    use_ok("Sub::Contract",'contract','undef_or','defined_and');
};

# tests
sub is_integer {
    croak "undefined argument" if (!defined $_[0]);
    return $_[0] =~ /^\d+$/;
}

# test sub
sub test_contract {
    my @tests = @_;

    while (@tests) {
	my $func = shift @tests;
	my @args = @{ shift @tests };
	my $match = shift @tests;
	my $args = join(",", map({ (defined $_)?$_:"undef" } @args));

	eval {
	    no strict 'refs';

	    if ($func =~ /method/) {
		My::Test->$func(@args);
	    } elsif ($func =~ /scalar/) {
		my $a = &$func(@args);
	    } elsif ($func =~ /array/) {
		my @a = &$func(@args);
	    } else {
		&$func(@args);
	    }
	};

	if ($match) {
	    if ($match =~ /undefined argument/) {
		ok( $@ =~ /$match at .*15_test_complex_contracts.t line \d+/, "$func dies on getting [$args]" );
	    } else {
		ok( $@ =~ /$match.*\n.*main::contract_$func.*at .*15_test_complex_contracts.t line \d+/, "$func dies on getting [$args]" );
	    }
	} else {
	    ok( !defined $@ || $@ eq '', "$func does not die on getting [$args]" );
	}
    }
}

# contract 1
my $c1 = contract('scalar_add')
    ->in(\&is_integer,\&is_integer)
    ->out(\&is_integer)
    ->enable;

my $res = 3;

sub scalar_add {
    my ($a,$b) = @_;
    return $res;
}

test_contract(
	      # test no arguments
	      scalar_add => [ 1, 2 ],        undef,
	      scalar_add => [ 'a', 2 ],      "input argument number 1 of main::scalar_add fails its constraint",
	      scalar_add => [ 1, 'b' ],      "input argument number 2 of main::scalar_add fails its constraint",
	      scalar_add => [ 1, undef ],    "undefined argument",
	      scalar_add => [ 1, 3, undef ], "main::scalar_add expected exactly 2 input arguments but got 3",
	      );

$res = 'adb';
test_contract(
	      # test no arguments
	      scalar_add => [ 1, 2 ], "return value number 1 of main::scalar_add fails its constraint: adb",
	      );

# add a post condition to c1
$c1->post(sub {
    my ($a,$b) = @Sub::Contract::args;
#    print "got: ".Dumper(@Sub::Contract::args, \@_, $a+$b);
    return ($_[0] == $a+$b);
})->enable;

$res = 7;
test_contract(
	      scalar_add => [ 1, 6 ],        undef,
	      scalar_add => [ 3, 4 ],        undef,
	      scalar_add => [ 3, 3 ],        "post-condition fails after calling main::scalar_add",
	      scalar_add => [ 'a', 2 ],      "input argument number 1 of main::scalar_add fails its constraint",
	      scalar_add => [ 1, 'b' ],      "input argument number 2 of main::scalar_add fails its constraint",
	      scalar_add => [ 1, undef ],    "undefined argument",
	      scalar_add => [ 1, 3, undef ], "main::scalar_add expected exactly 2 input arguments but got 3",
	      );

# add a trickyer contract
contract('foo')
    ->in( undef,
	  \&is_integer,
	  undef,
	  a => undef_or(\&is_integer),
	  b => defined_and(\&is_integer),
	  )
    ->enable;

sub foo {
    my ($a,$b,$c,%hash) = @_;
}

test_contract(
	      foo => [ undef, 1, undef, a => 78, b => 89 ],    undef,
	      foo => [ 'abc', 1, undef, a => 78, b => 89 ],    undef,
	      foo => [ undef, 1, 'abn', a => 78, b => 89 ],    undef,
	      foo => [ undef, 1, undef, a => undef, b => 89 ], undef,
	      foo => [ undef, 1, undef, a => 78, b => 89 ],    undef,
	      foo => [ undef, 1, undef, b => 89, a => 67 ],    undef,
	      foo => [ undef, 1, undef, b => 89, a => undef ], undef,

	      # errors:
	      foo => [ undef, 1, undef, a => 78, b => 89, e => 7 ], "main::foo got unexpected hash-style input arguments: e",
	      foo => [ undef, undef, undef, a => 78, b => 89 ],     "undefined argument",
	      foo => [ undef, 1, undef, a => 'ad', b => 89 ],       "input argument of main::foo with key 'a' fails its constraint",
	      foo => [ undef, 1, undef, a => 78, b => undef ],      "input argument of main::foo with key 'b' fails its constraint",
	      foo => [ undef, 1, undef, b => undef, a => 67 ],      "input argument of main::foo with key 'b' fails its constraint",
	      foo => [ undef, 1, undef, 78, b => 89, a => 67 ],     "odd number of hash-style input arguments in main::foo",
	      foo => [ b => 89, undef ],                            "input argument of main::foo with key 'b' fails its constraint",
	      foo => [ ],                                           "undefined argument",
	      );


