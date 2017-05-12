use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Response;
use Test::MockModule;
use Test::Exception;
use URI;

BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::ClientLogin::Multiple';
}
my $ua = Test::MockModule->new('LWP::UserAgent');
ok my $auth = Net::Google::DataAPI::Auth::ClientLogin::Multiple->new(
    username => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
    services => {
        'docs.google.com' => 'writely',
        'spreadsheets.google.com' => 'wise',
        '*docs.googleusercontent.com' => 'writely'
    }
);
{
    $ua->mock(
        request => sub {
            my ($self, $req) = @_;
            is $req->method, 'POST';
            is $req->uri, 'https://www.google.com/accounts/ClientLogin';
            my $post = URI->new;
            $post->query($req->content);
            is_deeply {$post->query_form}, {
                accountType => 'HOSTED_OR_GOOGLE',
                Email => 'foo.bar@gmail.com',
                Passwd => 'p4ssw0rd',
                service => 'writely',
                source => 'Net::Google::DataAPI::Auth::ClientLogin::Multiple',
            };
            return HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth_for_writely
END
        }
    );

    my $req = HTTP::Request->new(
        GET => 'https://docs.google.com/feeds/default/private/full'
    );
    ok $auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth_for_writely'
}

{
    $ua->mock(
        request => sub {
            my ($self, $req) = @_;
            my $post = URI->new;
            $post->query($req->content);
            is {$post->query_form}->{service}, 'wise';
            return HTTP::Response->parse(<<END);
403 OK
Content-Type: text/plain

Url=http://www.google.com/login/captcha
Error=CaptchaRequired
CaptchaToken=MyCaptchaToken
CaptchaUrl=Captcha?ctoken=HiteT4b0Bk5Xg18_AcVoP6-yFkHPibe7O9EqxeiI7lUSN
END
        }
    );
    my $req = HTTP::Request->new(
        GET => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
    );
    throws_ok {
        $auth->sign_request($req);
    } qr{login for spreadsheets.google.com failed};
}
{
    $ua->mock(
        request => sub {
            my ($self, $req) = @_;
            my $post = URI->new;
            $post->query($req->content);
            is {$post->query_form}->{service}, 'wise';
            return HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth_for_wise
END
        }
    );
    my $req = HTTP::Request->new(
        GET => 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
    );
    ok $auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth_for_wise'
}
{
    $ua->mock(
        request => sub {
            my ($self, $req) = @_;
            my $post = URI->new;
            $post->query($req->content);
            is {$post->query_form}->{service}, 'writely';
            return HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth_for_writely
END
        }
    );
    my $req = HTTP::Request->new(
        GET => 'https://doc-0s-6s-docs.googleusercontent.com/docs/secure'
    );
    ok $auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth_for_writely'
}
{
    my $req = HTTP::Request->new(
        GET => 'https://docs.google.com/feeds/default/private/full'
    );
    ok $auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth_for_writely'
}
{
    my $req = HTTP::Request->new(
        GET => 'https://docs.google.com/feeds/default/private/full'
    );
    ok $auth->sign_request($req, 'spreadsheets.google.com');
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth_for_wise', 'overriding sign host';
}
{
    my $req = HTTP::Request->new(
        GET => 'http://www.yahoo.com',
    );
    throws_ok {
        $auth->sign_request($req);
    } qr{service for www.yahoo.com not defined};
}

done_testing;
