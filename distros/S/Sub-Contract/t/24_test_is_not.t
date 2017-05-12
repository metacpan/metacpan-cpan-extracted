#-------------------------------------------------------------------
#
#   $Id: 24_test_is_not.t,v 1.1 2009/06/03 17:36:56 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_not);

BEGIN {
    use check_requirements;
    plan tests => 5;
};

sub is_integer {
    croak "should not reach here" if (!defined $_[0]); 
    return ($_[0] =~ /^\d+$/)?1:0;
}

contract('foo')
    ->in(\&is_integer, is_not(\&is_integer))
    ->enable;

sub foo {
    my ($i,$ni) = @_;
    croak "undefined arg" if (!defined $i);
    return $i . $ni;
}

my $res;

eval { $res = foo(6,"abc") };
ok( !defined $@ || $@ eq '', "foo() ok on integer" );
is($res,"6abc","foo() returned correct value");

eval { $res = foo(6,"10") };
ok( $@ =~ /argument number 2 .* fails its constraint: 10/, "foo() dies if arg2 is integer" );

eval { $res = foo(6,123) };
ok( $@ =~ /argument number 2 .* fails its constraint: 123/, "foo() dies if arg2 is integer" );

eval { $res = foo("abc","abc") };
ok( $@ =~ /argument number 1 .* fails its constraint: abc/, "foo() dies if arg1 is string" );


