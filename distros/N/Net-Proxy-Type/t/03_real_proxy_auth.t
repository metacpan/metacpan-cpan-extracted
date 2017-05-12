use strict;
use Test::More;
use Net::Proxy::Type;

unless ($ENV{TEST_PROXY_HOST_AUTH}) {
	plan skip_all => 'TEST_PROXY_HOST_AUTH environment variable not set';
}
else {
	plan tests => 4
}

my $pt = Net::Proxy::Type->new();
is($pt->get("$ENV{TEST_PROXY_HOST_AUTH}:3128"), Net::Proxy::Type::CONNECT_PROXY, 'get for http(s)');
$pt->strict(1);
is($pt->get("$ENV{TEST_PROXY_HOST_AUTH}:3128"), Net::Proxy::Type::UNKNOWN_PROXY, 'get for http(s) (strict)');
$pt->strict(0);
$pt->noauth(1);
is($pt->get("$ENV{TEST_PROXY_HOST_AUTH}:3128"), Net::Proxy::Type::UNKNOWN_PROXY, 'get for http(s) (noauth)');
$pt->strict(1);
is($pt->get("$ENV{TEST_PROXY_HOST_AUTH}:3128"), Net::Proxy::Type::UNKNOWN_PROXY, 'get for http(s) (noauth strict)');

__END__

3proxy settings:
users admin:123Pass
auth strong
proxy
