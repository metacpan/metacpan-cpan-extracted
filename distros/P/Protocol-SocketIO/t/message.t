use strict;
use warnings;
use utf8;

use Encode ();

use Test::More tests => 31;

use_ok('Protocol::SocketIO::Message');

my $m = Protocol::SocketIO::Message->new(type => 'disconnect', endpoint => '/test');
is $m->to_bytes, '0::/test';

$m = Protocol::SocketIO::Message->new(type => 'disconnect');
is $m->to_bytes, '0';

$m = Protocol::SocketIO::Message->new(type => 'connect');
is $m->to_bytes, '1::';

$m = Protocol::SocketIO::Message->new(type => 'connect', endpoint => '/test?my=param');
is $m->to_bytes, '1::/test?my=param';

$m = Protocol::SocketIO::Message->new(type => 'heartbeat');
is $m->to_bytes, '2::';

$m = Protocol::SocketIO::Message->new(type => 'message', id => 1, data => 'blabla');
is $m->to_bytes, '3:1::blabla';

$m = Protocol::SocketIO::Message->new(type => 'message', id => 1, data => 'привет');
is $m->to_bytes, Encode::encode('UTF-8', '3:1::привет');

$m = Protocol::SocketIO::Message->new(type => 'message', id => 1, data => 'привет');
is $m->to_string, '3:1::привет';

$m = Protocol::SocketIO::Message->new(id => 1, data => 'blabla');
is $m->to_bytes, '3:1::blabla';

$m =
  Protocol::SocketIO::Message->new(type => 'json_message', id => 1, data => {a => 'b'});
is $m->to_bytes, '4:1::{"a":"b"}';

$m = Protocol::SocketIO::Message->new(id => 1, data => {a => 'b'});
is $m->to_bytes, '4:1::{"a":"b"}';

$m =
  Protocol::SocketIO::Message->new(type => 'json_message', id => 1, data => {a => 'привет'});
is $m->to_bytes, Encode::encode('UTF-8', '4:1::{"a":"привет"}');

$m = Protocol::SocketIO::Message->new(
    type => 'event',
    id   => 1,
    data => {name => 'foo', args => ['foo']}
);
like $m->to_bytes, qr/^5:1::\{.*\}$/;
like $m->to_bytes, qr/"args":\["foo"\]/;
like $m->to_bytes, qr/"name":"foo"/;

$m = Protocol::SocketIO::Message->new->parse('5:1+::{"args":["foo"],"name":"foo"}');
is $m->id => '1';

$m = Protocol::SocketIO::Message->new(type => 'ack', message_id => 4);
is $m->to_bytes, '6:::4';

$m = Protocol::SocketIO::Message->new(type => 'ack', message_id => 4, args => ['A', 'B']);
is $m->to_bytes, '6:::4+["A","B"]';

# TODO complex ack

$m = Protocol::SocketIO::Message->new(
    type     => 'error',
    reason   => 'foo',
    advice   => 'bar',
    endpoint => '/test'
);
is $m->to_bytes, '7::/test:foo+bar';

$m = Protocol::SocketIO::Message->new(type => 'noop');
is $m->to_bytes, '8';

$m = Protocol::SocketIO::Message->new->parse('5:1+::{"args":"foo"],"name":"foo"}');
ok(not defined $m);

$m = Protocol::SocketIO::Message->new->parse('foobar');
ok(not defined $m);

$m = Protocol::SocketIO::Message->new->parse('100:');
ok(not defined $m);

$m = Protocol::SocketIO::Message->new->parse('0::/test');
is $m->type,     'disconnect';
is $m->id,       '';
is $m->endpoint, '/test';
is $m->data,     '';

$m = Protocol::SocketIO::Message->new->parse('4:1::{"a":"b"}');
is_deeply $m->data, {a => 'b'};

$m =
  Protocol::SocketIO::Message->new->parse(Encode::encode('UTF-8', '3:1::привет'));
is $m->data, 'привет';

$m = Protocol::SocketIO::Message->new->parse(
    Encode::encode('UTF-8', '4:1::{"a":"привет"}'));
is_deeply $m->data, {a => 'привет'};
