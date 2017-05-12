#-------------------------------------------------------------------
#
#   $Id: 20_test_def_and_undef_or.t,v 1.1 2009/06/03 04:40:12 erwan_lemonnier Exp $
#

package Bob;

use lib "../lib/", "t/", "lib/";
use Carp qw(croak);
use Sub::Contract qw(contract undef_or defined_and);

# tests
sub is_integer {
    croak "undefined argument" if (!defined $_[0]);
    return $_[0] =~ /^\d+$/;
}

sub new { return bless({},"Bob"); }

# simulate an object method using undef_or and def_and
contract('add')
    ->in( undef,
	  a => undef_or(\&is_integer),
	  b => defined_and(\&is_integer),
	  )
    ->enable;

sub add {
    my ($self,%hash) = @_;
    $a = $hash{a} || 0;
    $b = $hash{b};
    return $a + $b;
}

1;

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {
    use check_requirements;
    plan tests => 10;
};


my $bob = new Bob;

# test sub
sub test_contract {
    my @tests = @_;

    while (@tests) {
	my @args = @{ shift @tests };
	my $want = shift @tests;
	my $match = shift @tests;
	my $args = join(",", map({ (defined $_)?$_:"undef" } @args));

	my $res;
	eval {
	    $res = $bob->add(@args);
	};

	if ($match) {
	    ok( $@ =~ /$match/, "add() dies on returning [$args]" );
	} else {
	    ok( !defined $@ || $@ eq '', "add() does not die on returning [$args]" );
	    is($res,$want,"add() returned correct value");
	}
    }
}

test_contract(
	      [ a => 1, b => 6 ], 7, undef,
	      [ a => 1, b => 4 ], 5, undef,
	      [ b => 1, a => 4 ], 5, undef,
	      [ a => undef, b => 4 ], 4, undef,
	      [ a => undef, b => undef ], undef, "input argument of Bob::add with key 'b' fails its constraint",
	      [ a => 'abc', b => undef ], undef, "input argument of Bob::add with key 'a' fails its constraint",
	      );


