#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Status qw/ :constants :is /;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

use Plack::Middleware::Security::Common;

my $handler = builder {
    enable "Security::Common",
        rules => [
            archive_extensions,
            cgi_bin,
            dot_files,
            non_printable_chars,
            null_or_escape,
            script_extensions,
            system_dirs,
            unexpected_content,
            webdav_methods,
            wordpress,
        ];

    sub { return [ HTTP_OK, [], ['Ok'] ] };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'not blocked' => sub {
        my $req = GET "/some/thing.html";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing.php";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing/?file=/etc/passwd";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/some/wp-login";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/data/backup.zip";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing.php?stuff=1";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = POST "/cgi-bin/thing?stuff=1";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked get with content body' => sub {
        my $req = GET "/some/thing.html";
        $req->content("search=evil hidden payload");
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'non-printable' => sub {
        my $req = GET "/this/thing" . chr(0);
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'non-printable' => sub {
        my $req = GET "/this/thing?q=" . chr(0);
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/admin/.htaccess";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'not blocked' => sub {
        my $req = GET "/.well-known/time";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

 };

done_testing;
