#-------------------------------------------------------------------
#
#   $Id: 11_test_out.t,v 1.5 2008/06/17 11:31:42 erwan_lemonnier Exp $
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
    plan tests => 98;

    use_ok("Sub::Contract",'contract');
};

# tests
sub is_integer {
    my $val = shift;
    my $res = (defined $val && $val =~ /^\d+$/) ? 1 : 0;
#    print "is_integer: checking ".((defined $val) ? $val:"undef")." - returns $res\n";
    return $res;
}
sub is_zero    {
#    print "is_zero: checking ".($_[0]||"undef")."\n";
    return defined $_[0] && $_[0] =~ /^0$/;
}

# functions to test
my @results;
my $results;

sub foo_none  { return @results; }
sub foo_one   { return $results; }
sub foo_array { return @results; }
sub foo_hash  { return @results; }
sub foo_mixed { return @results; }

# test pre condition
eval {
    # same for package function
    contract('foo_none')
	->out()
	->enable;

    contract('foo_one')
	->out(\&is_integer)
	->enable;

    contract('foo_array')
	->out(\&is_integer,
	      undef,
	      \&is_zero,
	      )
	->enable;

    contract('foo_hash')
	->out(a => \&is_zero,
	      b => \&is_integer,
	      )
	->enable;

    contract('foo_mixed')
	->out(undef,
	      \&is_integer,
	      a => \&is_zero,
	      b => \&is_integer,
	      )
	->enable;

};

ok(!defined $@ || $@ eq '', "compiled contracts");

my @tests = (
	     # test no arguments
	     foo_none => [],
	     undef,
	     "calling main::foo_none in scalar or array context",
	     "calling main::foo_none in scalar or array context",

 	     foo_none => [ 1 ],
	     "main::foo_none should return no values but returned 1",
	     "calling main::foo_none in scalar or array context",
	     "calling main::foo_none in scalar or array context",

 	     foo_none => [ undef ],
	     "main::foo_none should return no values but returned 1",
	     "calling main::foo_none in scalar or array context",
	     "calling main::foo_none in scalar or array context",

 	     # test 1 argument
 	     foo_one => [],
	     "return value number 1 of main::foo_one fails its constraint",
	     "return value number 1 of main::foo_one fails its constraint",
	     "calling main::foo_one in array context when its contract says it returns a scalar",

 	     foo_one => [ 2 ],
	     undef,
	     undef,
	     "calling main::foo_one in array context when its contract says it returns a scalar",

 	     foo_one => [ 'abc' ],
	     "return value number 1 of main::foo_one fails its constraint: abc",
	     "return value number 1 of main::foo_one fails its constraint: abc",
	     "calling main::foo_one in array context when its contract says it returns a scalar",

 	     foo_one => [ undef ],
	     "return value number 1 of main::foo_one fails its constraint: undef",
	     "return value number 1 of main::foo_one fails its constraint: undef",
	     "calling main::foo_one in array context when its contract says it returns a scalar",

 	     # test array arguments
 	     foo_array => [ 1234, undef, 0 ], undef, undef, undef,
 	     foo_array => [ 0, {}, 0 ], undef,undef,undef,
	     foo_array => [ 3485923847, 'abc', 0 ], undef,undef,undef,

	     foo_array => [ 1234, undef, 1 ],
	     "return value number 3 of main::foo_array fails its constraint",
	     "return value number 3 of main::foo_array fails its constraint",
	     "return value number 3 of main::foo_array fails its constraint",

	     foo_array => [ 1234, undef, undef ],
	     "return value number 3 of main::foo_array fails its constraint",
	     "return value number 3 of main::foo_array fails its constraint",
	     "return value number 3 of main::foo_array fails its constraint",

	     foo_array => [ 'abc', undef, 0 ],
	     "return value number 1 of main::foo_array fails its constraint",
	     "return value number 1 of main::foo_array fails its constraint",
	     "return value number 1 of main::foo_array fails its constraint",

	     foo_array => [ 1234, undef, 0, undef ],
	     "main::foo_array should return exactly 3 values but returned 4",
	     "main::foo_array should return exactly 3 values but returned 4",
	     "main::foo_array should return exactly 3 values but returned 4",

 	     foo_array => [ 1234, undef ],
	     "main::foo_array should return exactly 3 values but returned 2",
	     "main::foo_array should return exactly 3 values but returned 2",
	     "main::foo_array should return exactly 3 values but returned 2",

 	     foo_array => [ 1234 ],
	     "main::foo_array should return exactly 3 values but returned 1",
	     "main::foo_array should return exactly 3 values but returned 1",
	     "main::foo_array should return exactly 3 values but returned 1",

 	     foo_array => [ ],
	     "main::foo_array should return exactly 3 values but returned 0",
	     "main::foo_array should return exactly 3 values but returned 0",
	     "main::foo_array should return exactly 3 values but returned 0",

 	     # test hash arguments
 	     foo_hash => [ a => 0, b => 128376 ], undef,undef,undef,
 	     foo_hash => [ b => 128376, a => 0 ], undef,undef,undef,

 	     foo_hash => [ b => 128376, a => 0, c => 0 ],
	     "main::foo_hash returned unexpected hash-style return values: c",
	     "main::foo_hash returned unexpected hash-style return values: c",
	     "main::foo_hash returned unexpected hash-style return values: c",

 	     foo_hash => [ b => 128376, a => 0, 0 ],
	     "odd number of hash-style return values in main::foo_hash",
	     "odd number of hash-style return values in main::foo_hash",
	     "odd number of hash-style return values in main::foo_hash",

 	     foo_hash => [ b => 128376, a => 1 ],
	     "return value of main::foo_hash with key \'a\' fails its constraint",
	     "return value of main::foo_hash with key \'a\' fails its constraint",
	     "return value of main::foo_hash with key \'a\' fails its constraint",

 	     foo_hash => [ b => 128376, a => undef ],
	     "return value of main::foo_hash with key \'a\' fails its constraint",
	     "return value of main::foo_hash with key \'a\' fails its constraint",
	     "return value of main::foo_hash with key \'a\' fails its constraint",

 	     foo_hash => [ b => 'abc', a => 0 ],
	     "return value of main::foo_hash with key \'b\' fails its constraint",
	     "return value of main::foo_hash with key \'b\' fails its constraint",
	     "return value of main::foo_hash with key \'b\' fails its constraint",

 	     foo_hash => [ b => [0], a => 0 ],
	     "return value of main::foo_hash with key \'b\' fails its constraint",
	     "return value of main::foo_hash with key \'b\' fails its constraint",
	     "return value of main::foo_hash with key \'b\' fails its constraint",

	     # test mixed arguments
	     foo_mixed => [ 0, 123, a => 0, b => 128376 ], undef,undef,undef,
	     foo_mixed => [ 'abc', 654, a => 0, b => 1 ], undef,undef,undef,

	     foo_mixed => [ undef, 'abc', a => 0, b => 1 ],
	     "return value number 2 of main::foo_mixed fails its constraint",
	     "return value number 2 of main::foo_mixed fails its constraint",
	     "return value number 2 of main::foo_mixed fails its constraint",

	     foo_mixed => [ undef, 1, a => 1, b => 1 ],
	     "return value of main::foo_mixed with key \'a\' fails its constraint: a = 1",
	     "return value of main::foo_mixed with key \'a\' fails its constraint: a = 1",
	     "return value of main::foo_mixed with key \'a\' fails its constraint: a = 1",

	     foo_mixed => [ undef, 1, a => 0, b => undef ],
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",

	     foo_mixed => [ undef, 1, a => 0, b => undef, 12 ],
	     "odd number of hash-style return values in main::foo_mixed",
	     "odd number of hash-style return values in main::foo_mixed",
	     "odd number of hash-style return values in main::foo_mixed",

	     foo_mixed => [ undef, 1, a => 0 ],
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     "return value of main::foo_mixed with key \'b\' fails its constraint: b = undef",
	     );

while (@tests) {
    my $func         = shift @tests;
    @results         = @{ shift @tests };
    my $match_void   = shift @tests;
    my $match_scalar = shift @tests;
    my $match_array  = shift @tests;

    my $args = join(",", map({ (defined $_)?$_:"undef" } @results));

    if ($func eq "foo_one") {
	($results) = @results;
    }

    # call in void context
    eval {
	no strict 'refs';
	&$func();
    };

    if ($match_void) {
	ok( $@ =~ /$match_void/, "void context: $func dies on returning [$args]" );
    } else {
	ok( !defined $@ || $@ eq '', "void context: $func does not die on returning [$args]" );
    }

    # call in scalar context
    eval {
	no strict 'refs';
	my $s = &$func();
    };

    if ($match_scalar) {
	ok( $@ =~ /$match_scalar/, "scalar context: $func dies on returning [$args]" );
    } else {
	ok( !defined $@ || $@ eq '', "scalar context: $func does not die on returning [$args]" );
    }

    # call in array context
    eval {
	no strict 'refs';
	my @s = &$func();
    };

    if ($match_array) {
	ok( $@ =~ /$match_array/, "array context: $func dies on returning [$args]" );
    } else {
	ok( !defined $@ || $@ eq '', "array context: $func does not die on returning [$args]" );
    }
}


