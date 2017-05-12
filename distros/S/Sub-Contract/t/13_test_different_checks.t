#-------------------------------------------------------------------
#
#   $Id: 13_test_different_checks.t,v 1.3 2008/06/17 11:31:42 erwan_lemonnier Exp $
#

# test that different contracts do not affect each other internally

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {

    use check_requirements;
    plan tests => 17;

    use_ok("Sub::Contract",'contract');
};

sub is_a { return (defined $_[0] and $_[0] =~ /^a$/) ? 1:0; }
sub is_b { return (defined $_[0] and $_[0] =~ /^b$/) ? 1:0; }
sub is_c { return (defined $_[0] and $_[0] =~ /^c$/) ? 1:0; }
sub is_d { return (defined $_[0] and $_[0] =~ /^d$/) ? 1:0; }

is(is_a('a'),1,"is_a(a)");
is(is_a('b'),0,"is_a(b)");
is(is_b('a'),0,"is_a(a)");
is(is_b('b'),1,"is_a(b)");
is(is_c('c'),1,"is_a(c)");
is(is_c('d'),0,"is_a(d)");
is(is_d('d'),1,"is_a(d)");
is(is_d('b'),0,"is_a(b)");

my $res;

# functions to test
contract('foo1')
    ->in(\&is_a,\&is_c)
    ->out(\&is_b)
    ->enable;

contract('foo2')
    ->in(\&is_b,\&is_d)
    ->out(\&is_a)
    ->enable;

sub foo1 { return $res; }
sub foo2 { return $res; }

# test foo_none
my @tests = ( # args, result, error
	      foo1 => ['a','c'], 'b', undef,
	      foo2 => ['b','d'], 'a', undef,

	      # errors
	      foo2 => ['a','c'], 'b', "input argument number 1 of main::foo2",
	      foo2 => ['b','c'], 'b', "input argument number 2 of main::foo2",
	      foo2 => ['b','d'], 'd', "return value number 1 of main::foo2",

	      foo1 => ['b','d'], 'a', "input argument number 1 of main::foo1",
	      foo1 => ['a','d'], 'a', "input argument number 2 of main::foo1",
	      foo1 => ['a','c'], 'a', "return value number 1 of main::foo1",
	     );


while (@tests) {
    my $func    = shift @tests;
    my @args    = @{ shift @tests };
    $res        = shift @tests;
    my $match   = shift @tests;
    my $arg_str = join(",", map({ (defined $_)?$_:"undef" } @args));

    eval {
	no strict 'refs';
	my $s = $func->(@args);
    };

    if ($match) {
	ok( $@ =~ /$match/, "$func dies on getting [$arg_str] and returning [".$res."]" );
    } else {
	ok( !defined $@ || $@ eq '', "$func does not die on getting [$arg_str] and returning [".$res."]" );
    }
}

