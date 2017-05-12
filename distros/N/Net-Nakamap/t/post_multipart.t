use strict;
use warnings;

use FindBin;
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

subtest 'file path' => sub {
    my $ua    = LWP::UserAgent->new();
    my $guard = mock_guard $ua => {
    request => sub {
        my ($self, $req) = @_;

        like $req->{_content}, qr/name="icon"/;
        like $req->{_content}, qr/filename="test\.txt"/;
        like $req->{_content}, qr!Content-Type: text/plain\r\n\r\ntest!;

        my $res = Test::MockObject->new();
        $res->mock( 'content',    sub { '{"icon":"abcdabcdabcdabcdabcdabcdabcdabcd"}' } );
        $res->mock( 'is_success', sub { 1 } );

        return $res;
    },
    };

    my $nakamap = create_nakamap($ua);
    my $result  = $nakamap->post('/1/me/icon', {}, {
        icon => "$FindBin::Bin/test.txt",
    });

    ok $result->{icon};
    ok ! $nakamap->last_error;
};

subtest 'binary' => sub {
    my $ua    = LWP::UserAgent->new();
    my $guard = mock_guard $ua => {
    request => sub {
        my ($self, $req) = @_;

        like $req->{_content}, qr/name="icon"/;
        like $req->{_content}, qr/filename="upload"/;
        like $req->{_content}, qr!Content-Type: application/octet-stream\r\n\r\nbinary data!;

        my $res = Test::MockObject->new();
        $res->mock( 'content',    sub { '{"icon":"abcdabcdabcdabcdabcdabcdabcdabcd"}' } );
        $res->mock( 'is_success', sub { 1 } );

        return $res;
    },
    };

    my $nakamap = create_nakamap($ua);
    my $result  = $nakamap->post('/1/me/icon', {}, {
        icon => \'binary data',
    });

    ok $result->{icon};
    ok ! $nakamap->last_error;
};

done_testing;
