use strict;
use warnings;

use Test::More tests => 8;

use_ok('Protocol::SocketIO::Path');

my $path = Protocol::SocketIO::Path->new->parse('//');
ok(not defined $path);

$path = Protocol::SocketIO::Path->new->parse('/1/');
ok($path);

$path = Protocol::SocketIO::Path->new->parse('/1/');
is($path->protocol_version, 1);

$path = Protocol::SocketIO::Path->new->parse('/1/');
ok($path->is_handshake);

$path = Protocol::SocketIO::Path->new->parse('/1/abc/123');
ok(not defined $path);

$path = Protocol::SocketIO::Path->new->parse('/1/xhr-polling/123');
ok($path);

$path = Protocol::SocketIO::Path->new->parse('/1/xhr-polling/123');
ok(!$path->is_handshake);
