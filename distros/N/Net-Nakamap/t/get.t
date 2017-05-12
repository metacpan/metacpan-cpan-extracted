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
        get => sub {
            my $res = Test::MockObject->new();
            $res->mock( 'content',    sub { '[{"title":"my groups"}]' } );
            $res->mock( 'is_success', sub { 1 } );

            return $res;
        },
    };

    my $nakamap = create_nakamap($ua);
    my $groups  = $nakamap->get('/1/groups');

    is $groups->[0]{title}, 'my groups';
    ok ! $nakamap->last_error;
};

subtest 'fail' => sub {
    my $ua    = LWP::UserAgent->new();
    my $guard = mock_guard $ua => {
        get => sub {
            my $res = Test::MockObject->new();
            $res->mock( 'content',    sub { '{"error":["something is wrong"]}' } );
            $res->mock( 'is_success', sub { 0 } );

            return $res;
        },
    };

    my $nakamap = create_nakamap($ua);
    my $groups  = $nakamap->get('/1/groups');

    ok ! $groups;
    is $nakamap->last_error, '{"error":["something is wrong"]}';
};

done_testing;
