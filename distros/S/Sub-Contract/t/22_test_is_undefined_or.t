#-------------------------------------------------------------------
#
#   $Id: 22_test_is_undefined_or.t,v 1.1 2009/06/03 04:40:12 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);
use Sub::Contract qw(contract is_undefined_or);

BEGIN {
    use check_requirements;
    plan tests => 4;
};

sub is_integer {
    croak "should not reach here" if (!defined $_[0]); 
    return ($_[0] =~ /^\d+$/)?1:0;
}

contract('incr')
    ->in(is_undefined_or(\&is_integer))
    ->enable;

sub incr {
    my $i = shift;
    croak "undefined arg" if (!defined $i);
    return $i+1;
}

my $res;

eval { $res = incr(6) };
ok( !defined $@ || $@ eq '', "incr() ok on integer" );
is($res,7,"incr() returned correct value");

eval { $res = incr(undef) };
ok( $@ =~ /undefined arg/, "incr() dies if undef" );

eval { $res = incr("abc") };
ok( $@ =~ /fails its constraint: abc/, "incr() dies if not integer" );


