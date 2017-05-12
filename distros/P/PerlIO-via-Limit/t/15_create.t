use strict;
use Test::More tests => 5;

use PerlIO::via::Limit;

isa_ok(PerlIO::via::Limit->create,'PerlIO::via::Limit');

isnt( PerlIO::via::Limit->create, PerlIO::via::Limit->create, 'create different class');

is(PerlIO::via::Limit->create->length, undef, 'default length');

ok( ! PerlIO::via::Limit->create->sensitive, 'default sensitive');

my $limit = PerlIO::via::Limit->create(10);
is($limit->length, 10, 'set limit passing parameter');
