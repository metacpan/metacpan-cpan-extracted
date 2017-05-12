use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Exception;
use LWP::UserAgent;
use URI;
use JSON;
BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::OAuth2';
}
{
    throws_ok sub {
        Net::Google::DataAPI::Auth::OAuth2->new(
            client_secret => 'foobar',
        )
    }, qr/Attribute \(client_id\) is required/;
}
{
    throws_ok sub {
        Net::Google::DataAPI::Auth::OAuth2->new(
            client_id => 'myclient.example.com',
        )
    }, qr/Attribute \(client_secret\) is required/;
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    my $i = 0;
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'POST';
            my $q = {URI->new('?'.$req->content)->query_form};
            $i++;
            if ($i == 1) {
                is_deeply $q, {
                    grant_type => 'authorization_code',
                    redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
                    client_secret => 'mysecret',
                    client_id => 'myclient.example.com',
                    code => 'mycode',
                };
            } else {
                is_deeply $q, {
                    grant_type => 'refresh_token',
                    client_secret => 'mysecret',
                    client_id => 'myclient.example.com',
                    refresh_token => 'my_refresh_token',
                };
            }
            my $res = HTTP::Response->new(200);
            $res->header('Content-Type' => 'text/json');
            my $json = to_json({
                    access_token => 'my_access_token',
                    refresh_token => 'my_refresh_token',
                    expires_in => 20,
                }
            );
            $res->content($json);
            return $res;
        }
    );
    ok my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => 'myclient.example.com',
        client_secret => 'mysecret',
        state => '',
    );
    ok my $url = $oauth2->authorize_url;
    $url = URI->new($url);
    is $url->scheme, 'https';
    is $url->host, 'accounts.google.com';
    is $url->path, '/o/oauth2/auth';
    is_deeply {$url->query_form}, {
        client_id => 'myclient.example.com',
        redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
        response_type => 'code',
        scope => 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email',
        state => '',
    } or note explain {$url->query_form};

    ok my $access_token = $oauth2->get_access_token('mycode');
    is $access_token->access_token, 'my_access_token';
    is $access_token->refresh_token, 'my_refresh_token';
    my $req = HTTP::Request->new('get' => 'http://foo.bar.com');
    ok $oauth2->sign_request($req);
    is $req->header('Authorization'), 'Bearer my_access_token';
    
}
{
    ok my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => 'myclient.example.com',
        client_secret => 'mysecret',
        redirect_uri => 'https://example.com/callback',
        scope => ['http://spreadsheets.google.com/feeds/'],
        state => 'hogehoge',
    );
    ok my $url = $oauth2->authorize_url;
    $url = URI->new($url);
    is $url->scheme, 'https';
    is $url->host, 'accounts.google.com';
    is $url->path, '/o/oauth2/auth';
    is_deeply {$url->query_form}, {
        client_id => 'myclient.example.com',
        redirect_uri => 'https://example.com/callback',
        response_type => 'code',
        scope => 'http://spreadsheets.google.com/feeds/',
        state => 'hogehoge',
    } or note explain {$url->query_form};

#    ok $oauth2->get_access_token('mycode');
}
{
    ok my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id => 'myclient.example.com',
        client_secret => 'mysecret',
        redirect_uri => 'https://example.com/callback',
        scope => ['http://spreadsheets.google.com/feeds/'],
        state => 'foobar',
    );
    ok my $url = $oauth2->authorize_url(access_type => 'offline', approval_prompt => 'force');
    $url = URI->new($url);
    is $url->scheme, 'https';
    is $url->host, 'accounts.google.com';
    is $url->path, '/o/oauth2/auth';
    is_deeply {$url->query_form}, {
        client_id => 'myclient.example.com',
        redirect_uri => 'https://example.com/callback',
        response_type => 'code',
        scope => 'http://spreadsheets.google.com/feeds/',
        access_type => 'offline',
        approval_prompt => 'force',
        state => 'foobar',
    } or note explain {$url->query_form};

#    ok $oauth2->get_access_token('mycode');
}


done_testing;
