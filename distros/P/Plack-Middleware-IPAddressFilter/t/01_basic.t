use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

# $Plack::Test::Impl = "Server";

my $base_app = sub { return return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $_[0]->{REMOTE_ADDR}" ] ] };

{
    $app = builder {
        enable 'IPAddressFilter', rules => [ '+ 127.0.0.1' ];
        $base_app;
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;
    };
}

{
    $app = builder {
        enable 'IPAddressFilter', rules => [ '+ 192.168.0.1/24' ];
        $base_app;
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 403;
    };
}

done_testing;
