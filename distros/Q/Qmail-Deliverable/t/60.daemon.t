use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable;
use QDTest qw(setup_abs_fixtures start_daemon stop_daemon);

my $fixtures = setup_abs_fixtures();
my ( $pid, $port ) = start_daemon( qmail_dir => $fixtures );

my $base = "http://127.0.0.1:$port";

sub uri_escape {
    my ($value) = @_;
    $value =~ s/([^A-Za-z0-9\-\._~])/sprintf("%%%02X", ord($1))/eg;
    return $value;
}

sub request {
    my ( $method, $path, $content, $req_port ) = @_;
    $req_port //= $port;
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $req_port,
        Proto    => 'tcp',
        Timeout  => 5,
    ) or die "connect: $!";

    my $request = join "",
        "$method /$path HTTP/1.0\r\n",
        "Host: 127.0.0.1:$req_port\r\n",
        "Connection: close\r\n",
        ( defined $content ? "Content-Length: " . length($content) . "\r\n" : "" ),
        "\r\n",
        ( defined $content ? $content : "" );
    print {$sock} $request or die "write: $!";

    my $response = do { local $/; <$sock> };
    close $sock;
    my ( $headers, $body ) = split /\r?\n\r?\n/, $response, 2;
    my ($status_line) = split /\r?\n/, $headers, 2;
    my ($code)        = $status_line =~ /^HTTP\/\d+\.\d+\s+([0-9]+)\b/
        or die "bad response: $status_line";

    return {
        code        => $code,
        content     => defined $body ? $body : '',
        status_line => $status_line,
    };
}

sub GET { request( 'GET', $_[0], undef, $_[1] ) }
sub POST { request( 'POST', $_[0], $_[1] ) }

END {
    stop_daemon($pid) if $pid;
}

subtest 'qmail_local: known local address' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape('alice@sub.example.com') );
    is $r->{code},    200,     '200 OK';
    is $r->{content}, 'alice', 'body is the local part';
};

subtest 'qmail_local: virtualdomain' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape('bob@example.com') );
    is $r->{code},    200,               '200 OK';
    is $r->{content}, 'example.com-bob', 'prepend applied';
};

subtest 'qmail_local: unknown domain -> 204 UNDEF' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape('user@nowhere.test') );
    is $r->{code}, 204, '204 No Content for undef result';
};

subtest 'deliverable: known address' => sub {
    my $r = GET( "qd1/deliverable?" . uri_escape('alice@sub.example.com') );
    is $r->{code},    200,                   '200 OK';
    is $r->{content}, sprintf( '%d', 0xf1 ), 'body is the decimal status code (0xf1)';
};

subtest 'deliverable: non-local domain' => sub {
    my $r = GET( "qd1/deliverable?" . uri_escape('user@nowhere.test') );
    is $r->{code},    200,                   '200 OK';
    is $r->{content}, sprintf( '%d', 0xff ), '0xff';
};

subtest 'unknown command under /qd1/ -> 403' => sub {
    my $r = GET("qd1/not_a_command?foo");
    is $r->{code}, 403, 'forbidden';
};

subtest 'path outside /qd1/ -> 403' => sub {
    my $r = GET("other/path");
    is $r->{code}, 403, 'forbidden';
};

subtest 'POST not allowed -> 403' => sub {
    my $r = POST( "qd1/qmail_local", 'alice@sub.example.com' );
    is $r->{code}, 403, 'POST forbidden';
};

subtest 'non-ASCII query -> 400' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape("a\x00b") );
    is $r->{code}, 400, '400 Bad Request for non-printable arg';
};

subtest 'SIGHUP rereads config' => sub {

    # Before: example.com is a virtualdomain with prepend 'example.com'.
    my $before = GET( "qd1/qmail_local?" . uri_escape('x@example.com') );
    is $before->{content}, 'example.com-x', 'initial qmail_local result reflects current config';

    # Rewrite virtualdomains so example.com is no longer listed.
    open my $fh, '>', "$fixtures/control/virtualdomains" or die $!;
    print {$fh} "catchall.example:catchall\n.wild.org:wild\n";
    close $fh;

    kill 'HUP', $pid;

    # Poll for the change to take effect.
    my $after;
    for ( 1 .. 30 ) {
        my $r = GET( "qd1/qmail_local?" . uri_escape('x@example.com') );
        if ( $r->{code} == 204 ) { $after = $r; last; }
        select undef, undef, undef, 0.1;
    }
    ok $after && $after->{code} == 204, 'after SIGHUP, example.com is no longer local';
};

subtest 'command with no query string -> 400' => sub {
    my $r = GET("qd1/qmail_local");
    is $r->{code}, 400, 'missing query string is Bad Request';
};

subtest 'command with empty query string -> 400' => sub {
    my $r = GET("qd1/qmail_local?");
    is $r->{code}, 400, 'empty query string is Bad Request';
};

subtest 'plus-sign in local part survives percent-encoding roundtrip' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape('alice+tag@sub.example.com') );
    is $r->{code},    200,         '200 OK';
    is $r->{content}, 'alice+tag', '+ survives encode/decode';
};

subtest 'percent-sign in local part survives percent-encoding roundtrip' => sub {
    my $r = GET( "qd1/qmail_local?" . uri_escape('alice%test@sub.example.com') );
    is $r->{code},    200,          '200 OK';
    is $r->{content}, 'alice%test', '% survives encode/decode';
};

subtest 'internal exception in dispatched sub -> 500' => sub {
    my ( $epid, $eport ) = start_daemon(
        qmail_dir => $fixtures,
        pre_hook  => sub {
            no warnings 'redefine';
            *Qmail::Deliverable::qmail_local = sub { die "injected error\n" };
        },
    );
    my $r = GET( "qd1/qmail_local?" . uri_escape('alice@sub.example.com'), $eport );
    is $r->{code}, 500, 'unhandled exception returns 500 not 204';
    stop_daemon($epid);
};

done_testing();
