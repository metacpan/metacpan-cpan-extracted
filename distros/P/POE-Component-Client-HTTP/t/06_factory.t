# vim: filetype=perl sw=2 ts=2 expandtab

use strict;
use warnings;

use Test::More tests => 13;

use POE::Component::Client::HTTP::RequestFactory;
#use HTTP::Request;

ok (defined $INC{"POE/Component/Client/HTTP/RequestFactory.pm"}, "loaded");

eval {POE::Component::Client::HTTP::RequestFactory->new('foo')};
like($@, qr/expects its arguments/, "Argument format");

eval {POE::Component::Client::HTTP::RequestFactory->new([])};
like($@, qr/expects its arguments/, "Argument format");

eval {POE::Component::Client::HTTP::RequestFactory->new({Agent => {}})};
like($@, qr/Agent must be/, "Agent parameter");

my $f = POE::Component::Client::HTTP::RequestFactory->new;
isa_ok ($f, 'POE::Component::Client::HTTP::RequestFactory');
like ($f->[0]->[0], qr/^POE-Component-Client-HTTP/, 'Agent string');

$f = POE::Component::Client::HTTP::RequestFactory->new({Agent => 'foo'});
is ($f->[0]->[0], 'foo', 'custom Agent string');

eval {POE::Component::Client::HTTP::RequestFactory->new({Proxy => ['foo']})};
like($@, qr/Proxy must contain/, "Proxy parameter as list");

eval {POE::Component::Client::HTTP::RequestFactory->new({Proxy => 'foo'})};
like($@, qr/Proxy must contain/, "Proxy parameter as string");

$f = POE::Component::Client::HTTP::RequestFactory->new({Proxy => 'foo:80'});
is_deeply ($f->[7]->[0], ['foo', 80], 'correct Proxy string');

$f = POE::Component::Client::HTTP::RequestFactory->new({Proxy => ['foo',80]});
is_deeply ($f->[7]->[0], ['foo', 80], 'correct Proxy list');

$f = POE::Component::Client::HTTP::RequestFactory->new(
  {Protocol => 'HTTP/1.0'}
);
is ($f->[3], 'HTTP/1.0', 'Protocol string');

# especially for coverage :)
$f = POE::Component::Client::HTTP::RequestFactory->new({Protocol => ''});
is ($f->[3], 'HTTP/1.1', 'empty Protocol string');
