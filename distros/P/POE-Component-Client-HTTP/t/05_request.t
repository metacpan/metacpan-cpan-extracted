# vim: filetype=perl sw=2 ts=2 expandtab

use strict;
use warnings;

use Test::More tests => 7;

use POE::Component::Client::HTTP::Request;
use HTTP::Request;


ok (defined $INC{"POE/Component/Client/HTTP/Request.pm"}, "loaded");

eval {POE::Component::Client::HTTP::Request->new ('one')};
like($@, qr/expects its arguments/, "parameter style");

eval {POE::Component::Client::HTTP::Request->new (one => 'two')};
like($@, qr/need a Request/, "Request parameter");

eval {POE::Component::Client::HTTP::Request->new (Request => 'two')};
like($@, qr/must be a HTTP::Request/, "Request parameter");

## Commented out in Request.pm
#eval {
#  POE::Component::Client::HTTP::Request->new(
#    Request => HTTP::Request->new ('http://localhost/')
#  )
#};
#like($@, qr/need a Tag/, "Tag parameter");

eval {
  POE::Component::Client::HTTP::Request->new(
    Request => HTTP::Request->new(GET => 'file:///localhost/')
  )
};
like($@, qr/need a Factory/, "Factory parameter");

eval {
  POE::Component::Client::HTTP::Request->new(
    Request => HTTP::Request->new(GET => 'file:///localhost/'),
    Factory => 1
  )
};
like($@, qr/Can't locate object method "port"/, "Appropriate Request");

my $r = POE::Component::Client::HTTP::Request->new(
  Request => HTTP::Request->new(GET => 'http://localhost/'),
  Factory => 1
);

isa_ok ($r, 'POE::Component::Client::HTTP::Request');
