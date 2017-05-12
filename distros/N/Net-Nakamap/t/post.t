use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Mock::Guard qw/mock_guard/;
use LWP::UserAgent;

use Net::Nakamap;

sub create_nakamap {
    my ($ua) = @_;

    return Net::Nakamap->new(
        client_id     => 'this_is_client_id',
        client_secret => 'this_is_client_secret',
        token         => 'this_is_token',
        ua            => $ua,
    );
}

subtest 'success' => sub {
    my $ua    = LWP::UserAgent->new();
    my $guard = mock_guard $ua => {
        post => sub {
            my $res = Test::MockObject->new();
            $res->mock( 'content',    sub { '{"success":"1"}' } );
            $res->mock( 'is_success', sub { 1 } );

            return $res;
        },
    };

    my $nakamap = create_nakamap($ua);
    my $result  = $nakamap->post('/1/me/profile');

    is $result->{success}, 1;
    ok ! $nakamap->last_error;
};

subtest 'fail' => sub {
    my $ua    = LWP::UserAgent->new();
    my $guard = mock_guard $ua => {
        post => sub {
            my $res = Test::MockObject->new();
            $res->mock( 'content',    sub { '{"error":["something is wrong"]}' } );
            $res->mock( 'is_success', sub { 0 } );

            return $res;
        },
    };

    my $nakamap = create_nakamap($ua);
    my $result  = $nakamap->post('/1/me/profile');

    ok ! $result;
    is $nakamap->last_error, '{"error":["something is wrong"]}';
};

done_testing;
