use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use Test::MockModule;
use Test::Exception;
use HTTP::Response;
use URI;

BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::OAuth';
}

{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('get' => sub {
            my $self = shift;
            my $uri = URI->new(shift);

            is $uri->host, 'www.google.com';
            is $uri->scheme, 'https';
            is $uri->path, '/accounts/OAuthGetRequestToken';
            is {$uri->query_form}->{oauth_consumer_key}, 'myconsumer.example.com';
            is {$uri->query_form}->{scope}, 'http://spreadsheets.google.com/feeds/ https://spreadsheets.google.com/feeds/';
            is {$uri->query_form}->{oauth_callback}, 'oob';

            my $q = URI->new;
            my $res = HTTP::Response->new(200);
            $q->query_form(
                oauth_token => 'myrequesttoken',
                oauth_token_secret => 'myrequesttokensecret',
            );
            $res->content($q->query);
            return $res;
        }
    );

    ok my $oauth = Net::Google::DataAPI::Auth::OAuth->new(
        scope => ['http://spreadsheets.google.com/feeds/', 'https://spreadsheets.google.com/feeds/'],
        consumer_key => 'myconsumer.example.com',
        consumer_secret => 'mys3cr3t',
    );
    ok $oauth->get_request_token;
    is $oauth->request_token, 'myrequesttoken';
    is $oauth->request_token_secret, 'myrequesttokensecret';

    ok my $url = $oauth->get_authorize_token_url;
    is $url, 'https://www.google.com/accounts/OAuthAuthorizeToken?oauth_token=myrequesttoken&hd=default&hl=en';

    $ua->mock('get' => sub {
            my ($self, $url) = @_;
            my $res = HTTP::Response->new(200);
            my $q = URI->new;
            $q->query_form(
                oauth_token => 'myaccesstoken',
                oauth_token_secret => 'myaccesstokensecret',
            );
            $res->content($q->query);
            return $res;
        }
    );

    ok $oauth->get_access_token({verifier => 'myverifier'});
    is $oauth->access_token, 'myaccesstoken';
    is $oauth->access_token_secret, 'myaccesstokensecret';

    my $req = HTTP::Request->new(
        GET => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
    );
    ok $oauth->sign_request($req);
    ok my $header = $req->header('Authorization');
    my ($name, $value) = split(/\s/, $header);
    is $name, 'OAuth';
    my %args = split(/[=,]/, $value);
    is $args{oauth_token}, '"myaccesstoken"';
    is $args{oauth_signature_method}, '"HMAC-SHA1"';
    is $args{oauth_consumer_key}, '"myconsumer.example.com"'
}
{
    ok my $oauth = Net::Google::DataAPI::Auth::OAuth->new(
        scope => ['http://spreadsheets.google.com/feeds/'],
        consumer_key => 'myconsumer.example.com',
        consumer_secret => 'mys3cr3t',
    );

    my $req = HTTP::Request->new(
        GET => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
    );
    throws_ok {
        $oauth->sign_request($req)
    } qr{Missing required parameter 'token'};
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');

    ok my $oauth = Net::Google::DataAPI::Auth::OAuth->new(
        scope => ['http://spreadsheets.google.com/feeds/'],
        consumer_key => 'myconsumer.example.com',
        consumer_secret => 'mys3cr3t',
        callback => URI->new('http://myconsumer.example.com/callback'),
        authorize_token_hl => 'ja',
        mobile => 1,
    );

    {
        $ua->mock('get' => sub { });
        throws_ok { 
            $oauth->get_request_token; 
        } qr{request failed: no response returned};
    }
    {
        $ua->mock('get' => sub { HTTP::Response->new(400) });
        throws_ok { 
            $oauth->get_request_token; 
        } qr{request failed: 400 Bad Request};
    }
    {
        $ua->mock('get' => sub {
                my ($self, $url) = @_;
                my $res = HTTP::Response->new(200);
                my $q = URI->new;
                $q->query_form(
                    oauth_token => 'myrequesttoken',
                    oauth_token_secret => 'myrequesttokensecret',
                );
                $res->content($q->query);
                return $res;
            }
        );
        ok my $url = $oauth->get_authorize_token_url;
        my $uri = URI->new($url);
        is $uri->host, 'www.google.com';
        is $uri->scheme, 'https';
        is $uri->path, '/accounts/OAuthAuthorizeToken';
        is_deeply {$uri->query_form}, {
            oauth_token => 'myrequesttoken',
            hd => 'default',
            hl => 'ja',
            btmpl => 'mobile',
        };
    }
    {
        $ua->mock('get' => sub {
                my $self = shift;
                my $uri = URI->new(shift);
                my $res = HTTP::Response->new(200);
                my $q = URI->new;
                $q->query_form(
                    oauth_token => 'mytoken',
                    oauth_token_secret => 'mysecret',
                );
                $res->content($q->query);
                return $res;
            }
        );
        throws_ok {
            $oauth->get_access_token
        } qr{Missing required parameter 'verifier'};
        throws_ok {
            $oauth->sign_request( HTTP::Request->new(get => 'http://example.com/') )
        } qr{Missing required parameter 'token'};
        ok $oauth->get_access_token({verifier => 'myverifier'});
        my $req = HTTP::Request->new(get => 'http://example.com/');
        ok $oauth->sign_request($req);
        ok my $header = $req->header('Authorization');
        my ($name, $value) = split(/\s/, $header);
        is $name, 'OAuth';
        my %args = split(/[=,]/, $value);
        is $args{oauth_token}, '"mytoken"';
        is $args{oauth_signature_method}, '"HMAC-SHA1"';
        is $args{oauth_consumer_key}, '"myconsumer.example.com"';
    }
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');

    ok my $oauth = Net::Google::DataAPI::Auth::OAuth->new(
        scope => ['http://spreadsheets.google.com/feeds/'],
        consumer_key => 'myconsumer.example.com',
        consumer_secret => 'mys3cr3t',
        callback => 'myconsumer.example.com',
        authorize_token_hl => 'ja',
        mobile => 1,
    );

    {
        $ua->mock('get' => sub { });
        throws_ok { 
            $oauth->get_request_token; 
        } qr{request failed: no response returned};
    }
    {
        $ua->mock('get' => sub { HTTP::Response->new(400) });
        throws_ok { 
            $oauth->get_request_token; 
        } qr{request failed: 400 Bad Request};
    }
    {
        $ua->mock('get' => sub {
                my ($self, $url) = @_;
                my $res = HTTP::Response->new(200);
                my $q = URI->new;
                $q->query_form(
                    oauth_token => 'myrequesttoken',
                    oauth_token_secret => 'myrequesttokensecret',
                );
                $res->content($q->query);
                return $res;
            }
        );
        ok my $url = $oauth->get_authorize_token_url;
        my $uri = URI->new($url);
        is $uri->host, 'www.google.com';
        is $uri->scheme, 'https';
        is $uri->path, '/accounts/OAuthAuthorizeToken';
        is_deeply {$uri->query_form}, {
            oauth_token => 'myrequesttoken',
            hd => 'default',
            hl => 'ja',
            btmpl => 'mobile',
        };
    }
    {
        $ua->mock('get' => sub {
                my $self = shift;
                my $uri = URI->new(shift);
                my $res = HTTP::Response->new(200);
                my $q = URI->new;
                $q->query_form(
                    oauth_token => 'mytoken',
                    oauth_token_secret => 'mysecret',
                );
                $res->content($q->query);
                return $res;
            }
        );
        throws_ok {
            $oauth->get_access_token
        } qr{Missing required parameter 'verifier'};
        throws_ok {
            $oauth->sign_request( HTTP::Request->new(get => 'http://example.com/') )
        } qr{Missing required parameter 'token'};
        ok $oauth->get_access_token({verifier => 'myverifier'});
        my $req = HTTP::Request->new(get => 'http://example.com/');
        ok $oauth->sign_request($req);
        ok my $header = $req->header('Authorization');
        my ($name, $value) = split(/\s/, $header);
        is $name, 'OAuth';
        my %args = split(/[=,]/, $value);
        is $args{oauth_token}, '"mytoken"';
        is $args{oauth_signature_method}, '"HMAC-SHA1"';
        is $args{oauth_consumer_key}, '"myconsumer.example.com"';
    }
}

done_testing;
