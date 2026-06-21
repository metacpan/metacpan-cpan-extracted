use strict;
use warnings;
use Test::More;
use POE::Component::Server::JSONUnix;

# A stand-in server that just records what _send() was asked to deliver.
{
    package Mock::Server;
    sub new  { bless { sent => [] }, shift }
    sub _send {
        my ( $self, $id, $data ) = @_;
        push @{ $self->{sent} }, { id => $id, data => $data };
        return;
    }
}

my $CTX = 'POE::Component::Server::JSONUnix::Context';

subtest 'respond() defaults status, echoes id, targets wheel' => sub {
    my $mock = Mock::Server->new;
    my $ctx  = $CTX->_new(
        server => $mock, wheel_id => 11, req_id => 5,
        command => 'x', request => {},
    );
    $ctx->respond( { result => { ok => 1 } } );

    is( scalar @{ $mock->{sent} }, 1, 'sent exactly once' );
    my $sent = $mock->{sent}[0];
    is( $sent->{id}, 11, 'delivered to the right wheel id' );
    is( $sent->{data}{status}, 'ok', 'status defaults to ok' );
    is( $sent->{data}{id},     5,    'request id echoed back' );
    is_deeply( $sent->{data}{result}, { ok => 1 }, 'result passed through' );
    ok( $ctx->responded, 'context marked as responded' );
};

subtest 'a second respond() is ignored' => sub {
    my $mock = Mock::Server->new;
    my $ctx  = $CTX->_new(
        server => $mock, wheel_id => 1, req_id => 1,
        command => 'x', request => {},
    );
    $ctx->respond( { result => 1 } );
    $ctx->respond( { result => 2 } );
    is( scalar @{ $mock->{sent} }, 1, 'only one response sent' );
    is( $mock->{sent}[0]{data}{result}, 1, 'first response wins' );
};

subtest 'respond_result() wraps as {ok, result}' => sub {
    my $mock = Mock::Server->new;
    my $ctx  = $CTX->_new(
        server => $mock, wheel_id => 1, req_id => 9,
        command => 'x', request => {},
    );
    $ctx->respond_result( { a => 1 } );
    my $env = $mock->{sent}[0]{data};
    is( $env->{status}, 'ok', 'status ok' );
    is_deeply( $env->{result}, { a => 1 }, 'result wrapped' );
    is( $env->{id}, 9, 'id echoed' );
};

subtest 'error() sets error status and extra fields' => sub {
    my $mock = Mock::Server->new;
    my $ctx  = $CTX->_new(
        server => $mock, wheel_id => 1, req_id => undef,
        command => 'x', request => {},
    );
    $ctx->error( 'boom', detail => 'xyz' );
    my $env = $mock->{sent}[0]{data};
    is( $env->{status}, 'error', 'status error' );
    is( $env->{error},  'boom',  'error message set' );
    is( $env->{detail}, 'xyz',   'extra fields included' );
    ok( !exists $env->{id}, 'no id key when the request carried none' );
};

subtest 'accessors expose request data' => sub {
    my $req = { command => 'do', id => 3, args => { n => 1 } };
    my $ctx = $CTX->_new(
        server => Mock::Server->new, wheel_id => 1, req_id => 3,
        command => 'do', request => $req,
    );
    is( $ctx->command, 'do', 'command()' );
    is( $ctx->id,      3,    'id()' );
    is_deeply( $ctx->request, $req, 'request()' );
};

done_testing();
