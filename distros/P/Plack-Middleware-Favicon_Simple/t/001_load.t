use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok('Plack::Middleware::Favicon_Simple') };

my $obj = Plack::Middleware::Favicon_Simple->new;
can_ok($obj, 'call');
can_ok($obj, 'favicon');
isa_ok($obj, 'Plack::Middleware::Favicon_Simple');
isa_ok($obj, 'Plack::Middleware');
is($obj->favicon('foo'), 'foo', 'favicon');
