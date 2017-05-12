use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Exception;
use Test::MockObject;
use HTTP::Response;

{
    package MyService;
    use Any::Moose;
    use Net::Google::AuthSub;
    use Net::Google::DataAPI::Auth::AuthSub;
    with 'Net::Google::DataAPI::Role::Service';

    has password => (is => 'ro', isa => 'Str');
    has username => (is => 'ro', isa => 'Str');

    sub _build_auth {
        my ($self) = @_;
        my $authsub = Net::Google::AuthSub->new(
            service => 'wise',
            source => $self->source,
        );
        my $res = $authsub->login($self->username, $self->password);
        unless ($res && $res->is_success) {
            die 'Net::Google::AuthSub login failed';
        }
        return  Net::Google::DataAPI::Auth::AuthSub->new(
            authsub => $authsub
        );
    }
}

ok my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);

my $res = Test::MockObject->new;
$res->mock(is_success => sub {1});
my $authsub = Test::MockModule->new('Net::Google::AuthSub');
$authsub->mock(login => sub {return $res});
$authsub->mock(auth_params => sub {(Authorization => 'GoogleLogin ="MYAuth"')}); 

my $ua = Test::MockModule->new('LWP::UserAgent');
my $ua_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

OK
END

my $res_308 = HTTP::Response->new(308, 'Resume Incomplete');
$res_308->header(Range => '0-524287');
$res_308->header(Location => 'http://example.com/next');

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'GET';
            is $req->uri, 'http://example.com/myfeed';
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            uri => 'http://example.com/myfeed',
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'POST';
            is $req->uri, 'http://example.com/myfeed';
            is $req->content, 'foobar';
            is $req->header('Content-Type'), 'text/plain';
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            uri => 'http://example.com/myfeed',
            content => 'foobar',
            content_type => 'text/plain',
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'POST';
            is $req->uri, 'http://example.com/myfeed';
            is $req->content, 'foobar';
            is $req->header('Content-Type'), 'text/plain';
            is $req->header('If-Match'), '*';
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            uri => 'http://example.com/myfeed',
            content => 'foobar',
            header => {
                'If-Match' => '*',
            },
            content_type => 'text/plain',
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'DELETE';
            is $req->uri, 'http://example.com/myentry';
            is $req->header('If-Match'), '"hogehoge"';
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            method => 'DELETE',
            uri => 'http://example.com/myentry',
            header => {
                'If-Match' => '"hogehoge"',
            },
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'PUT';
            is $req->uri, 'http://example.com/myentry';
            is $req->header('If-Match'), '"hogehoge"';
            is $req->header('Content-Type'), 'text/plain';
            is $req->content, 'foobar',
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            method => 'PUT',
            uri => 'http://example.com/myentry',
            content_type => 'text/plain',
            header => {
                'If-Match' => '"hogehoge"',
            },
            content => 'foobar',
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            ok $req;
            is $req->method, 'POST';
            is $req->uri, 'http://example.com/myentry';
            is $req->header('If-Match'), '"hogehoge"';
            is [split(/;/, $req->header('Content-Type'))]->[0], 'multipart/related';
            is $req->content, 'foobar',
            return $ua_res;
        }
    );
    ok my $res = $s->request(
        {
            uri => 'http://example.com/myentry',
            parts => [
                HTTP::Message->new(
                    ['Content-Type' => 'application/atom+xml'],
                    <<END
<?xml version="1.0" encoding="utf-8">
<entry />
END
                ),
                HTTP::Message->new(
                    ['Content-Type' => 'text/plain'],
                    'hogehoge',
                ),
            ],
            header => {
                'If-Match' => '"hogehoge"',
            },
        }
    );
    ok $res->is_success;
    is $res->content, "OK\n";
}
{
    throws_ok { 
        $s->request(
            {
                uri => 'http://example.com/myentry',
                parts => [
                    'hoge',
                ],
            }
        )
    } qr{part argument should be a HTTP::Message object};
}

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            return $res_308;
        }
    );
    ok my $res = $s->request({method => 'PUT', uri => 'http://example.com/myfeed'});
    is $res->code, 308;
}

done_testing;
