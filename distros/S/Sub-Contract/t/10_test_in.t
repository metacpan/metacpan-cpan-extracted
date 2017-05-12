#-------------------------------------------------------------------
#
#   $Id: 10_test_in.t,v 1.5 2008/06/17 11:31:42 erwan_lemonnier Exp $
#

package My::Test;

sub new { return bless({},'My::Test'); }
sub method_hash { return 1; }

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {

    use check_requirements;
    plan tests => 38;

    use_ok("Sub::Contract",'contract');
};

# tests
sub is_integer {
#    print "is_integer: checking ".($_[0]||"undef")."\n";
    return defined $_[0] && $_[0] =~ /^\d+$/;
}
sub is_zero    {
#    print "is_zero: checking ".($_[0]||"undef")."\n";
    return defined $_[0] && $_[0] =~ /^0$/;
}

# functions to test
sub foo_none  { return 1; }
sub foo_array { return 1; }
sub foo_hash  { return 1; }
sub foo_mixed { return 1; }

# test pre condition
eval {
    # same for package function
    contract('foo_none')
	->in()
	->enable;

    contract('foo_array')
	->in(\&is_integer,
	     undef,
	     \&is_zero,
	     )
	->enable;

    contract('foo_hash')
	->in(a => \&is_zero,
	     b => \&is_integer,
	     )
	->enable;

    contract('foo_mixed')
	->in(undef,
	     \&is_integer,
	     a => \&is_zero,
	     b => \&is_integer,
	     )
	->enable;

    # same for object methods
    contract('My::Test::method_hash')
	->in(undef,
	     a => \&is_zero,
 	     b => \&is_integer,
 	     )
 	->enable;

};

ok(!defined $@ || $@ eq '', "compiled contracts");

my @tests = (
	     # test no arguments
	     foo_none => [], undef,
	     foo_none => [ 1 ], "main::foo_none expected no input arguments but got 1",
	     foo_none => [ undef ], "main::foo_none expected no input arguments but got 1",

	     # test array arguments
	     foo_array => [ 1234, undef, 0 ], undef,
	     foo_array => [ 0, {}, 0 ], undef,
	     foo_array => [ 3485923847, 'abc', 0 ], undef,
	     foo_array => [ 1234, undef, 1 ], "input argument number 3 of main::foo_array fails its constraint: 1",
	     foo_array => [ 1234, undef, undef ], "input argument number 3 of main::foo_array fails its constraint: undef",
	     foo_array => [ 'abc', undef, 0 ], "input argument number 1 of main::foo_array fails its constraint: abc",

	     foo_array => [ 1234, undef, 0, undef ], "main::foo_array expected exactly 3 input arguments but got 4",
	     foo_array => [ 1234, undef ], "main::foo_array expected exactly 3 input arguments but got 2",
	     foo_array => [ 1234 ], "main::foo_array expected exactly 3 input arguments but got 1",
	     foo_array => [ ], "main::foo_array expected exactly 3 input arguments but got 0",

	     # test hash arguments
	     foo_hash => [ a => 0, b => 128376 ], undef,
	     foo_hash => [ b => 128376, a => 0 ], undef,
	     foo_hash => [ b => 128376, a => 0, c => 0 ], "main::foo_hash got unexpected hash-style input arguments: c",
	     foo_hash => [ b => 128376, a => 0, 0 ], "odd number of hash-style input arguments in main::foo_hash",
	     foo_hash => [ b => 128376, a => 1 ], "input argument of main::foo_hash with key \'a\' fails its constraint: a = 1",
	     foo_hash => [ b => 128376, a => undef ], "input argument of main::foo_hash with key \'a\' fails its constraint: a = undef",
	     foo_hash => [ b => 'abc', a => 0 ], "input argument of main::foo_hash with key \'b\' fails its constraint: b = abc",
	     foo_hash => [ b => [0], a => 0 ], "input argument of main::foo_hash with key \'b\' fails its constraint: b = ARRAY",

	     # test mixed arguments
	     foo_mixed => [ 0, 123, a => 0, b => 128376 ], undef,
	     foo_mixed => [ 'abc', 654, a => 0, b => 1 ], undef,
	     foo_mixed => [ undef, 'abc', a => 0, b => 1 ], "input argument number 2 of main::foo_mixed fails its constraint: abc",
	     foo_mixed => [ undef, 1, a => 1, b => 1 ], "input argument of main::foo_mixed with key \'a\' fails its constraint: a = 1",
	     foo_mixed => [ undef, 1, a => 0, b => undef ], "input argument of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     foo_mixed => [ undef, 1, a => 0, b => undef, 12 ], "odd number of hash-style input arguments in main::foo_mixed",
	     foo_mixed => [ undef, 1, a => 0 ], "input argument of main::foo_mixed with key \'b\' fails its constraint: b = undef",

	     # test method call
	     method_hash => [ a => 0, b => 128376 ], undef,
	     method_hash => [ b => 1, a => 0 ], undef,
	     method_hash => [ b => 128376, a => 0, c => 0 ], "My::Test::method_hash got unexpected hash-style input arguments: c",
	     method_hash => [ b => 128376, a => 0, 0 ], "odd number of hash-style input arguments in My::Test::method_hash",
	     method_hash => [ b => 128376, a => 1 ], "input argument of My::Test::method_hash with key \'a\' fails its constraint: a = 1",
	     method_hash => [ b => 128376, a => undef ], "input argument of My::Test::method_hash with key \'a\' fails its constraint: a = undef",
	     method_hash => [ b => 'abc', a => 0 ], "input argument of My::Test::method_hash with key \'b\' fails its constraint: b = abc",
	     method_hash => [ b => [0], a => 0 ], "input argument of My::Test::method_hash with key \'b\' fails its constraint: b = ARRAY",

	     );

while (@tests) {
    my $func = shift @tests;
    my @args = @{ shift @tests };
    my $match = shift @tests;
    my $args = join(",", map({ (defined $_)?$_:"undef" } @args));

    eval {
	no strict 'refs';

	if ($func =~ /method/) {
	    My::Test->$func(@args);
	} else {
	    &$func(@args);
	}
    };

    if ($match) {
	ok( $@ =~ /$match.*\n.*(My::Test|main)::contract_$func\(.*at .*10_test_in.t line \d+/, "$func dies on arguments [$args]" );
    } else {
	ok( !defined $@ || $@ eq '', "$func does not die on arguments [$args]" );
    }
}



