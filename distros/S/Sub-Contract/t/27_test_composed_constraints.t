#-------------------------------------------------------------------
#
#   $Id: 27_test_composed_constraints.t,v 1.1 2009/06/03 17:36:56 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_undefined_or is_all_of is_not is_one_of);

BEGIN {
    use check_requirements;
    plan tests => 6;
};

sub is_abc { return ($_[0] eq "abc")?1:0; }
sub is_def { return ($_[0] eq "def")?1:0; }
sub is_ghi { return ($_[0] eq "ghi")?1:0; }

contract('foo')
    ->in(is_one_of(is_not(\&is_abc),\&is_def),is_undefined_or(\&is_ghi))
    ->enable;

sub foo {
    my ($a,$b) = @_;
    return $a.$b;
}

my $res;

eval { $res = foo("def","ghi") };
ok( !defined $@ || $@ eq '', "foo(def,ghi) ok" );
is($res,"defghi","foo() returned correct value");

eval { $res = foo("abc","ghi") };
ok( $@ =~ /fails its constraint: abc/, "foo(abc,ghi)" );

eval { $res = foo("aaa","ghi") }; 
ok( !defined $@ || $@ eq '', "foo(aaa,ghi) ok" );
is($res,"aaaghi","foo() returned correct value");

eval { $res = foo("aaa","bbb") };
ok( $@ =~ /fails its constraint: bbb/, "foo(aaa,bbb)" );



