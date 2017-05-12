use strict;
use warnings;
use Test::More tests => 8;
use Test::Fatal;

use Net::TinyERP;

ok 1, 'Net::TinyERP loaded successfully';

can_ok 'Net::TinyERP', qw( new nota_fiscal );

my $tiny;

like(
    exception { $tiny = Net::TinyERP->new },
    qr/precisa do argumento "token"/,
    'raises exception on missing arguments'
);

like(
    exception { $tiny = Net::TinyERP->new( foo => 42 ) },
    qr/argumento "token"/,
    'raises exception on missing token',
);

like(
    exception { $tiny = Net::TinyERP->new( token => undef ) },
    qr/argumento "token"/,
    'raises exception on undef token',
);

ok $tiny = Net::TinyERP->new( token => 'abc123' )
    => 'no exception when passing token to new()';

isa_ok $tiny, 'Net::TinyERP';
can_ok $tiny, 'nota_fiscal';


