#-------------------------------------------------------------------
#
#   $Id: 08_test_in_out_arguments_validation.t,v 1.3 2008/04/25 13:14:37 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    use check_requirements;
    plan tests => 104;

    use_ok("Sub::Contract",'contract');
    use_ok("Sub::Contract::Pool");
};

sub foo { 1 }

my $c = contract('foo');

my @tests = (
	     # arguments     # expected error or undef if ok

	     # those syntaxes are ok
	     [ undef, undef ], undef,
	     [], undef,
	     [ undef, 'blah' => undef ], undef,
	     [ undef, 'blah' => undef, 'boum' => undef ], undef,
	     [ 'blah' => undef, 'boum' => undef ], undef,

	     # this is not ok, since off number of args in hash
	     [ 'blah' => undef, 'boum' ], "odd number of arguments from position 0 in in..",
	     [ undef,undef,'blah' => undef, 'boum' ], "odd number of arguments from position 2 in in..",
	     [ undef,'abc' ], "odd number of arguments from position 1 in in..",

	     # same with coderefs
	     [ \&foo, \&foo], undef,
	     [], undef,
	     [ \&foo, 'blah' => \&foo ], undef,
	     [ \&foo, 'blah' => \&foo, 'boum' => \&foo ], undef,
	     [ 'blah' => \&foo, 'boum' => undef ], undef,
	     [ \&foo, \&foo, \&foo, undef ], undef,
	     [ 'blah' => \&foo, 'boum' ], "odd number of arguments from position 0 in in..",
	     [ \&foo,\&foo,'blah' => undef, 'boum' ], "odd number of arguments from position 2 in in..",
	     [ \&foo,'abc' ], "odd number of arguments from position 1 in in..",

	     # test errors with coderefs
	     [ [] ], "argument at position 0 in in.. should be undef or a coderef or a string",
	     [ {} ], "argument at position 0 in in.. should be undef or a coderef or a string",
	     [ \&foo, [] ], "argument at position 1 in in.. should be undef or a coderef or a string",

	     # test hash-style constraints, invalid keys
	     [ \&foo, a => \&foo, b => \&foo, c => undef ], undef,
	     [ \&foo, a => \&foo, a => \&foo, a => undef ], "constraining argument \'a\' twice",
	     [ \&foo, a => \&foo, \&foo => \&foo ], "argument at position 3 should be a string",
	     [ \&foo, undef => \&foo, b => \&foo ], undef,    # that's ok: 'undef' is the key
	     [ \&foo, undef, \&foo, b => \&foo ], undef,      # we miss that misstake, too bad...
	     [ \&foo, undef, \&foo, undef => \&foo ], undef,  # we miss that misstake, too bad...
	     [ \&foo, a => \&foo, [] => \&foo ], "argument at position 3 should be a string",
	     [ \&foo, {} => \&foo, [] => \&foo ], "argument at position 1 in in.. should be undef or a coderef or a string",
	     [ \&foo, a => \&foo, bless({},'blob') => \&foo ], "argument at position 3 should be a string",

	     # test hash-style constraints, invalid coderefs
	     [ \&foo, a => \&foo, b => 'abc' ], "check for \'b\' should be undef or a coderef",
	     [ \&foo, a => \&foo, b => [] ], "check for \'b\' should be undef or a coderef",
	     [ \&foo, a => {}, [] => \&foo ], "check for \'a\' should be undef or a coderef",
	     [ \&foo, a => \&foo, gnark => bless({},'blob') ], "check for \'gnark\' should be undef or a coderef",

	     );

my $line = 0;
while (@tests) {
    my $args = shift @tests;
    my $error = shift @tests;
    $line++;

    # test in()
    eval { $c->in(@{$args}); };

    if ($error) {
	ok( $@ =~ /$error/, "args $line lead to correct error in in()");
	ok( $@ =~ /at .*08_test_in_out_arguments_validation.t line 82/, "in() returns correct error message")
    } else {
	ok( !defined $@ || $@ eq '', "args $line are correct in in()");
    }

    # test out()
    eval { $c->out(@{$args}); };

    if ($error) {
	$error =~ s/in\.\./out\.\./;
	ok( $@ =~ /$error/, "args $line lead to correct error in out()");
	ok( $@ =~ /at .*08_test_in_out_arguments_validation.t line \d+/, "out() returns correct error message");
    } else {
	ok( !defined $@ || $@ eq '', "args $line are correct in out()");
    }
}
