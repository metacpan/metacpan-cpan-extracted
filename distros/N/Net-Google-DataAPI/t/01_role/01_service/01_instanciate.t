use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject;
use Test::MockModule;
use URI::Escape;
use HTTP::Response;

BEGIN {
    use_ok('Net::Google::DataAPI::Role::Service');
}


{
    package MyService;
    use Any::Moose;
    use Net::Google::AuthSub;
    use Net::Google::DataAPI::Auth::AuthSub;
    with 'Net::Google::DataAPI::Role::Service';
    has '+gdata_version' => (default => '3.0');
    has '+source' => (default => __PACKAGE__);

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

        return Net::Google::DataAPI::Auth::AuthSub->new(
            authsub => $authsub,
        );
    }
}

{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            is $request->method, 'POST';
            is $request->uri, 'https://www.google.com/accounts/ClientLogin';
            my $args = +{ map {uri_unescape $_} split('[&=]', $request->content) };
            is_deeply $args, {
                accountType => 'HOSTED_OR_GOOGLE',
                Email => 'example@gmail.com',
                Passwd => 'foobar',
                service => 'wise',
                source => 'MyService',
            };
            return HTTP::Response->parse(<<'END');
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth
END
        }
    );

    my $service = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );

    isa_ok $service, 'MyService';
    my $req = HTTP::Request->new;
    ok $service->auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=MYAuth';
    is $service->ua->default_headers->header('GData_Version'), '3.0';
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            return HTTP::Response->parse(<<'END');
403 Access Frobidden
Content-Type: text/plain

Url=http://www.google.com/login/captcha
Error=CaptchaRequired
CaptchaToken=MyCaptchaToken
CaptchaUrl=Captcha?ctoken=HiteT4b0Bk5Xg18_AcVoP6-yFkHPibe7O9EqxeiI7lUSN
END
        }
    );
    throws_ok {
        my $service = MyService->new(
            username => 'example@gmail.com',
            password => 'foobar',
        );
        my $req = HTTP::Request->new;
        $service->auth->sign_request($req);
    } qr{Net::Google::AuthSub login failed};
}
{
    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {
            return;
        }
    );
    throws_ok {
        my $service = MyService->new(
            username => 'example@gmail.com',
            password => 'foobar',
        );
        my $req = HTTP::Request->new;
        $service->auth->sign_request($req);
    } qr{Net::Google::AuthSub login failed};
}
{
    my $u = 'example@gmail.com';
    my $p = 'foobar';
    my $s = 'mysource';

    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {1});

    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {
            my ($self, $user, $pass) = @_;
            is $self->{source}, $s;
            is $user, $u;
            is $pass, $p;
            return $res
        }
    );
    $auth->mock(auth_params => sub {
            (Authorization => 'GoogleLogin auth=foobar')
        }
    );

    ok my $service = MyService->new(
        username => $u,
        password => $p,
        source => $s,
    );

    isa_ok $service, 'MyService';
    my $req = HTTP::Request->new;
    ok $service->auth->sign_request($req);
    is $req->header('Authorization'), 'GoogleLogin auth=foobar';
    is $service->ua->default_headers->header('GData_Version'), '3.0';
}

done_testing;
