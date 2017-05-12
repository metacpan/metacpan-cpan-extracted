use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static::OpenFileCache;
use Plack::Builder;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use HTTP::Request::Common;
use Plack::Test;

my $dir = tempdir( CLEANUP => 1 );
copy('t/share/face.jpg', "$dir/face.jpg");

my $handler = builder {
    enable "Static::OpenFileCache",
        path => sub { s!^/static/!!},
        root => "$dir",
        expires => 2;
    sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
    };
};

test_psgi(
    client => sub {
        my $cb  = shift;
        {
            my $res = $cb->(GET "http://localhost/static/face.jpg");
            is $res->content_type, 'image/jpeg';
        }
        move("$dir/face.jpg","$dir/face.jpg2");
        {
            my $res = $cb->(GET "http://localhost/static/face.jpg");
            is $res->content_type, 'image/jpeg';
        }
        sleep 3;
        {
            my $res = $cb->(GET "http://localhost/static/face.jpg");
            is $res->code, 404;
        }        
    },
    app => $handler,
);


done_testing;

