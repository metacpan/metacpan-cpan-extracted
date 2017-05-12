use strict;
use warnings;
use Test::More tests => 3;
use URI;
use Net::OpenID::Consumer::Lite;

{
    my $check_url1 = Net::OpenID::Consumer::Lite->check_url('https://mixi.jp/openid_server.pl', 'http://example.com/');
    my $u1 = URI->new($check_url1);
    my $e = URI->new('https://mixi.jp/openid_server.pl?openid.mode=checkid_immediate&openid.return_to=http%3A%2F%2Fexample.com%2F');
    is($u1->path, $e->path);
    is_deeply(+{$u1->query_form}, +{$e->query_form});
}

{
    my $check_url2 = Net::OpenID::Consumer::Lite->check_url('https://mixi.jp/openid_server.pl', 'http://example.com/', {
        "http://openid.net/extensions/sreg/1.1" => { required => join( ",", qw/email nickname/ ) }
    });
    is_deeply(
        +{URI->new($check_url2)->query_form()},
        +{URI->new('https://mixi.jp/openid_server.pl?openid.mode=checkid_immediate&openid.return_to=http%3A%2F%2Fexample.com%2F&openid.ns.e1=http://openid.net/extensions/sreg/1.1&openid.e1.required=email,nickname')->query_form}
    );
}
