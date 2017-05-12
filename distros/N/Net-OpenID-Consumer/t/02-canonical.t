use strict;
use warnings;
no warnings 'redefine';
use Net::OpenID::Consumer;
use Test::More;

my @tests = qw(
  example.com  http://example.com/
  http://example.com  http://example.com/
  https://example.com  https://example.com/
  https://example.com/  https://example.com/
  http://example.com/user  http://example.com/user
  http://example.com/user/  http://example.com/user/
  http://example.com/  http://example.com/
);

{
    use integer;
    plan tests => (@tests / 2);
}

# stop Consumer to fetch HTML content from the URL
local *Net::OpenID::Consumer::_find_semantic_info = sub {
    my($self, $url, $final_url_ref) = @_;
    $$final_url_ref = $url;
    return { "openid.server" => "http://example.com/op" };
};
local *Net::OpenID::Yadis::discover = sub {};

while (my($url, $normalized) = splice(@tests, 0, 2)) {
    my $csr = Net::OpenID::Consumer->new;
    my $identity = $csr->claimed_identity($url);
    is $identity->claimed_url, $normalized, "$url -> $normalized";
}

