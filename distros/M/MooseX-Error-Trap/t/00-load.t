#!perl -T

use Test::More tests => 1;

BEGIN {

package My::Test;
use Moose;
use MooseX::Error::Trap;

1;

}

ok( My::Test->new );
diag( "Testing MooseX::Error::Trap $MooseX::Error::Trap::VERSION, Perl $], $^X" );
