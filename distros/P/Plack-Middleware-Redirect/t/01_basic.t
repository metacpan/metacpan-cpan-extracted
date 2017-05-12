use Test::Most;
use Plack::Test;
use Plack::Util;
use Plack::Builder;

{
    foreach my $test ( tests() ) {
        test_psgi
            app    => app(),
            client => client($test);
    }

    done_testing();
}

sub app {
    my $app = sub { [ 200, [ 'Content-Type' => 'text/plain' ], ["Hello"] ] };

    builder {
        enable 'Redirect', url_patterns => [
            '/old/path.html' => '/new/path.html',
            '/query.html'   => '/query.html?q=y',
            '^/status_code$'          => ['/permanent', 302],
            '^/(\d{4})_(\d{2})_(\d{2})$'       => '/$1/$2/$3',
            '^/code_(.+)$'           => [sub {
                my ($env, $regex) = @_;
                my $path = $env->{PATH_INFO};
                $path =~ m|$regex|;
                $path = join ("_", split("", $1)) if $1;
                return "/$path";
            }, 301],
        ];
        $app;
    };
}

sub client {
    my $test = shift;

    return sub {
        my $cb  = shift;
        my $url = "http://localhost" . $test->{url};
        my $req = HTTP::Request->new( GET => $url );
        my $res = $cb->($req);

        is $res->code(), $test->{status_code}, "HTTP status code: $test->{status_code}";

        if ( $test->{location} ) {
            is $res->header('Location'), $test->{location},
                "Res: $test->{location}";
        }
        if ( $test->{body} ){
            is $res->content, $test->{body}, "Checked body";
        }

    };
}

# -- everything below this line is test data

sub tests {
    return (
        {   
            url  => '/no_redirect',
            status_code => '200',
            body    => "Hello",
        },

        {   
            url  => '/status_code',
            location => '/permanent',
            status_code => '302',
            body    => "Found",
        },

        {   
            url  => '/code_abc',
            location => '/a_b_c',
            status_code => '301',
            body    => "Moved Permanently",
        },
    );
}                        
