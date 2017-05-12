use strict;
use warnings;
use Test::More;

use_ok 'Sub::Rate';

my $r = Sub::Rate->new( max_rate => 100 );

eval { $r->add( 50, sub {}) };
ok !$@, 'no error ok';

eval { $r->add( 50, sub {}) };
ok !$@, 'no error ok';

eval { $r->add( 50, sub {}) };
ok $@, 'exceeds rate ok';

done_testing;
