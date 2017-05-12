# custom_error_document.t

use Test::More;

use FindBin;
use Plack::Test;
use Plack::Middleware::ErrorDocument;
use Plack::Middleware::CustomErrorDocument;

my $app = sub {
    my $env = shift;

    my $status  = 200;
    my $headers = [ 'Content-Type' => 'text/plain' ];
    my $body    = ["ok"];

    if ( $env->{PATH_INFO} =~ m{^/(\d{3})} ) {
        $status = $1;
        $body   = ["$status error"];
    }

    return [ $status, $headers, $body ];
};

$app = Plack::Middleware::CustomErrorDocument->wrap(
    $app,
    404 => sub {
        my $env = shift;
        return "$FindBin::Bin/root/error_404.jpg"    #
            if $env->{PATH_INFO} =~ qr/\.jpe?g$/;
        return "$FindBin::Bin/root/error_404_$1.html"
            if $env->{PATH_INFO} =~ qr/(special)/;  # example of using capture
        return "$FindBin::Bin/root/error_404.html"; # default
    },
);

$app = Plack::Middleware::ErrorDocument->wrap(      #
    $app,
    500 => 't/root/error_500.html',
);

#------------------------------------------------------------------------------

my @tests = (

    # no error
    {   uri          => '/',
        status       => 200,
        content      => 'ok',
        content_type => 'text/plain',
    },

    # standard ErrorDocumnent
    {   uri          => '/500.html',
        status       => 500,
        content_type => 'text/html',
        content_like =>
            qr{<html><body><h1>500 Server Error</h1></body></html>},
    },
    {   uri          => '/500.jpg',
        status       => 500,
        content_type => 'text/html',
        content_like =>
            qr{<html><body><h1>500 Server Error</h1></body></html>},
    },

    # CustomErrorDocument
    {   uri          => '/404.html',
        status       => 404,
        content_type => 'text/html',
        content_like => qr{<html><body><h1>404 Not Found</h1></body></html>},
    },
    {   uri          => '/404.jpg',
        status       => 404,
        content_type => 'image/jpeg',
    },
    {   uri          => '/404_special.html',
        status       => 404,
        content_type => 'text/html',
        content_like =>
            qr{<html><body><h1>Page not found :\(</h1></body></html>},
    },
);

foreach my $test (@tests) {
    note $test->{uri};

    test_psgi
        app    => $app,
        client => sub {
        my $cb = shift;

        my $req = HTTP::Request->new( 'GET', $test->{uri} );
        my $res = $cb->($req);

        is $res->code, $test->{status},
            "Got correct status: " . $test->{status};

        is $res->header('Content-Type'), $test->{content_type},
            "Got correct content-type: " . $test->{content_type};

        if ( $test->{content} ) {
            is $res->content, $test->{content}, "got correct content";
        } elsif ( $test->{content_like} ) {
            like $res->content, $test->{content_like}, "got correct content";
        }

        };
}

done_testing();
