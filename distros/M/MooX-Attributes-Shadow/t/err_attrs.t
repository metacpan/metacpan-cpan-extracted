#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't';

use Container1;

throws_ok { Container1::run_shadow_attrs( attrs => 3 ); } qr/invalid type/, 'bad attrs';

throws_ok { Container1->new->foo } qr/must first be shadowed/, 'no attrs';

throws_ok { Container1::run_shadow_attrs( ); } qr/must specify attrs/, 'bad attrs';


done_testing;
