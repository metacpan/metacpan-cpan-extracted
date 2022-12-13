package main;

use 5.006;

use strict;
use warnings;

use PPIx::Regexp::Constant;	# This gets us ::Inf
use Test::More 0.88;	# Because of done_testing();

use constant BIG	=> 6.02e23;	# An arbitrary large number

# DANGER WILL ROBINSON! ENCAPSULATION VIOLATION!
use constant INF	=> PPIx::Regexp::Constant::Inf->__pos_inf();

ok INF, 'Inf is true';

is INF, 'Inf', q<Inf stringifies to 'Inf'>;

cmp_ok INF, '==', INF, 'Inf is equal to itself';

cmp_ok INF, '>', BIG, 'Inf is greater than a large number';

cmp_ok INF + BIG, '==', INF, 'Inf plus a large number is still Inf';

cmp_ok INF - BIG, '==', INF, 'Inf minus a large number is still Inf';

done_testing;

1;

# ex: set textwidth=72 :
