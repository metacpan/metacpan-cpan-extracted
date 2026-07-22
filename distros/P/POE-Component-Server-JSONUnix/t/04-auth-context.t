use strict;
use warnings;
use Test::More;
use POE::Component::Server::JSONUnix;

# Unit-test the three auth accessors on the Context object without a live
# server.  We use the same Mock::Server pattern as 02-context.t, but the mock
# now carries a clients hash so the accessors can look up auth state.

{
    package Mock::Server;
    sub new {
        bless {
            sent    => [],
            clients => {},
        }, shift;
    }
    sub _send {
        my ( $self, $id, $data ) = @_;
        push @{ $self->{sent} }, { id => $id, data => $data };
    }
}

my $CTX = 'POE::Component::Server::JSONUnix::Context';

sub make_ctx {
    my ( $mock, $wheel_id ) = @_;
    return $CTX->_new(
        server   => $mock,
        wheel_id => $wheel_id,
        req_id   => 1,
        command  => 'test',
        request  => {},
    );
}

subtest 'authenticated() is false before auth_verify' => sub {
    my $mock = Mock::Server->new;
    $mock->{clients}{1} = { auth_uid => undef, auth_username => undef };
    my $ctx = make_ctx( $mock, 1 );
    ok( !$ctx->authenticated, 'authenticated() returns false' );
    is( $ctx->uid,      undef, 'uid() is undef' );
    is( $ctx->username, undef, 'username() is undef' );
};

subtest 'authenticated() is true after auth_verify' => sub {
    my $mock = Mock::Server->new;
    $mock->{clients}{2} = { auth_uid => 1000, auth_username => 'alice' };
    my $ctx = make_ctx( $mock, 2 );
    ok( $ctx->authenticated, 'authenticated() returns true' );
    is( $ctx->uid,      1000,    'uid() returns the stored uid' );
    is( $ctx->username, 'alice', 'username() returns the stored username' );
};

subtest 'uid 0 is treated as authenticated (root)' => sub {
    my $mock = Mock::Server->new;
    $mock->{clients}{3} = { auth_uid => 0, auth_username => 'root' };
    my $ctx = make_ctx( $mock, 3 );
    ok( $ctx->authenticated, 'uid 0 counts as authenticated' );
    is( $ctx->uid, 0, 'uid() returns 0' );
};

subtest 'accessors are independent per wheel_id' => sub {
    my $mock = Mock::Server->new;
    $mock->{clients}{10} = { auth_uid => 500,  auth_username => 'bob' };
    $mock->{clients}{11} = { auth_uid => undef, auth_username => undef };

    my $ctx_authed   = make_ctx( $mock, 10 );
    my $ctx_unauthed = make_ctx( $mock, 11 );

    ok( $ctx_authed->authenticated,   'wheel 10 is authenticated' );
    ok( !$ctx_unauthed->authenticated, 'wheel 11 is not authenticated' );
    is( $ctx_authed->uid,      500,   'wheel 10 uid correct' );
    is( $ctx_unauthed->uid,    undef, 'wheel 11 uid is undef' );
    is( $ctx_authed->username, 'bob', 'wheel 10 username correct' );
};

done_testing();
