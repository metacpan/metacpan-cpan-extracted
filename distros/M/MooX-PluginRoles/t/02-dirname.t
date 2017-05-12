use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Quux plugins => ['Bar'];
use Quux::A;

my $a = Quux::A->new;

can_ok( $a, 'a' );
can_ok( $a, 'bar_a' );

done_testing;
