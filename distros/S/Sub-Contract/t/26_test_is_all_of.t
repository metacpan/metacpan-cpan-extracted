#-------------------------------------------------------------------
#
#   $Id: 26_test_is_all_of.t,v 1.1 2009/06/03 17:36:56 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_all_of);

BEGIN {
    use check_requirements;
    plan tests => 3;
};


sub is_integer { return ($_[0] =~ /^\d+$/)?1:0; }
sub is_ten { return ($_[0] eq 10)?1:0; }

contract('foo')
    ->in(is_all_of(\&is_integer,\&is_ten))
    ->enable;

sub foo {
    my ($a) = @_;
    return $a+1;
}

my $res;

eval { $res = foo(10) };
ok( !defined $@ || $@ eq '', "foo(10)" );
is($res,11,"foo(10) returned correct value");

eval { $res = foo(123) };
ok( $@ =~ /argument number 1 .* fails its constraint: 123/, "foo(123) dies" );



