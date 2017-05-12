use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;
use URI;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], ["Hello"] ];
};

$app = builder {
    enable "OptionsOK", allow => 'GET POST';
    $app;
};

sub cb {
    my ( $username, $password ) = @_;
    return $username eq 'admin' && $password eq 's3cr3t';
}

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    my $req = HTTP::Request->new( 'GET', '/' );
    my $res = $cb->($req);
    is $res->code,    200;
    is $res->content, "Hello";

    $req = HTTP::Request->new( 'OPTIONS', '*' );
    $res = $cb->($req);
    is $res->header('Allow'), 'GET POST';
    is $res->code,    200;
    is $res->content, "";

    $req = HTTP::Request->new( 'OPTIONS', '/' );
    $res = $cb->($req);
    is $res->header('Allow'), 'GET POST';
    is $res->code,    200;
    is $res->content, "";

    };
done_testing;
