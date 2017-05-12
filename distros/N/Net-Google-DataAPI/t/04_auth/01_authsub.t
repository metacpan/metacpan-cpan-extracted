use strict;
use warnings;
use lib 't/lib';
use Test::More;
use MyService;
use Net::Google::AuthSub;
use Test::MockModule;
use Test::MockObject;
use URI::Escape;

BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::AuthSub';
}

my $ua = Test::MockModule->new('LWP::UserAgent');
$ua->mock(
    request => sub {
        my ($self, $req, $arg) = @_;
        is $req->method, 'POST';
        is $req->uri, 'https://www.google.com/accounts/ClientLogin';
        my $args = +{ map {uri_unescape $_} split('[&=]', $req->content) };
        is_deeply $args, {
            accountType => 'HOSTED_OR_GOOGLE',
            Email => 'foo.bar@gmail.com',
            Passwd => 'p4ssw0rd',
            service => 'wise',
            source => 'MyService',
        };
        return HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth
END
    }
);
my $authsub = Net::Google::AuthSub->new(
    service => 'wise',
    account_type => 'HOSTED_OR_GOOGLE',
    source => 'MyService',
);
ok my $res = $authsub->login('foo.bar@gmail.com', 'p4ssw0rd');
ok $res->is_success;
ok my $service = MyService->new(
    auth => $authsub,
);
isa_ok $service->auth, 'Net::Google::DataAPI::Auth::AuthSub';

done_testing;
