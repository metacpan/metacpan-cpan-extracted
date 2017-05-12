#-------------------------------------------------------------------
#
#   $Id: 25_test_is_one_of.t,v 1.1 2009/06/03 17:36:56 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_one_of);

BEGIN {
    use check_requirements;
    plan tests => 7;
};


sub is_abc { return ($_[0] eq "abc")?1:0; }
sub is_def { return ($_[0] eq "def")?1:0; }
sub is_ghi { return ($_[0] eq "ghi")?1:0; }

contract('foo')
    ->in(is_one_of(\&is_abc,\&is_def,\&is_ghi))
    ->enable;

sub foo {
    my ($a) = @_;
    return $a."!";
}

my $res;

eval { $res = foo("abc") };
ok( !defined $@ || $@ eq '', "foo(abc)" );
is($res,"abc!","foo() returned correct value");

eval { $res = foo("def") };
ok( !defined $@ || $@ eq '', "foo(def)" );
is($res,"def!","foo() returned correct value");

eval { $res = foo("ghi") };
ok( !defined $@ || $@ eq '', "foo(ghi)" );
is($res,"ghi!","foo() returned correct value");

eval { $res = foo(123) };
ok( $@ =~ /argument number 1 .* fails its constraint: 123/, "foo(123) dies" );



