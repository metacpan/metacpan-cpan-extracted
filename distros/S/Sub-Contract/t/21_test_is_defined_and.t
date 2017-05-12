#-------------------------------------------------------------------
#
#   $Id: 21_test_is_defined_and.t,v 1.1 2009/06/03 04:40:12 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_defined_and);

BEGIN {
    use check_requirements;
    plan tests => 4;
};

sub is_integer {
    croak "not an integer" if ($_[0] !~ /^\d+$/);
    return 1;
}

contract('incr')
    ->in(is_defined_and(\&is_integer))
    ->enable;

sub incr {
    my $i = shift;
    return $i+1;
}

my $res;

eval { $res = incr(6) };
ok( !defined $@ || $@ eq '', "incr() ok on integer" );
is($res,7,"incr() returned correct value");

eval { $res = incr(undef) };
ok( $@ =~ /fails its constraint: undef/, "incr() dies if undef" );

eval { $res = incr("abc") };
ok( $@ =~ /not an integer/, "incr() dies if not integer" );


