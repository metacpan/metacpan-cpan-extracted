use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Mock::Guard qw/mock_guard/;
use LWP::UserAgent;

use Net::Nakamap;

my $ua = LWP::UserAgent->new();
my $guard = mock_guard $ua => {
    post => sub {
        my $res = Test::MockObject->new();
        $res->mock( 'content',    sub { '{"access_token":"this_is_token"}' } );
        $res->mock( 'is_success', sub { 1 } );

        return $res;
    },
};

my $nakamap = Net::Nakamap->new(
    client_id     => 'this_is_client_id',
    client_secret => 'this_is_client_secret',
    ua            => $ua,
);

subtest 'auth url' => sub {
    my $auth_uri = $nakamap->auth_uri({
        response_type => 'code',
        scope         => 'read_basic write_basic',
    });

    my $expected = join '', qw(
        https://nakamap.com/dialog/oauth
        ?client_id=this_is_client_id
        &response_type=code
        &scope=read_basic+write_basic
    );

    is $auth_uri->as_string(), $expected;
};

subtest 'auth code' => sub {
    my $res = $nakamap->auth_code({
        code => 'auth_code',
    });

    is $res->{access_token}, 'this_is_token';
};

done_testing;
