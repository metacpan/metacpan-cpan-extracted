package t::easier;

use strict;
use warnings;
use autodie;

use Test2::V0 -no_utf8 => 1;
use Test2::Plugin::NoWarnings;

use parent 'Test::Class::Tiny';

use Socket;
use File::Temp;

use Net::Curl::Easier;

__PACKAGE__->new()->runtests() if ! caller;

sub SKIP_CLASS {
    return "No UNIX sockets available (OS = $^O)." if !Socket->can('AF_UNIX');

    if (!Net::Curl::Easier->can('CURLOPT_UNIX_SOCKET_PATH')) {
        return sprintf "This curl (%s) lacks CURLOPT_UNIX_SOCKET_PATH.", Net::Curl::version();
    }

    return;
}

sub _create_server {
    my ($end_re) = @_;

    die 'list!' if !wantarray;

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $path = "$dir/sock";

    socket my $psock, AF_UNIX, SOCK_STREAM, 0;
    bind $psock, Socket::pack_sockaddr_un($path);
    listen $psock, 1;

    pipe my $pr, my $cw;

    my $pid = fork or do {
        close $pr;

        my $csock;
        accept $csock, $psock;
        close $psock;

        my $got = q<>;
        while ($got !~ $end_re) {
            sysread $csock, $got, 512, length $got;
        }

        print {$csock} join(
            "\x0d\x0a",
            "HTTP/1.0 200 OK",
            'Content-Type: text/plain',
            q<>,
            'hello',
        );

        close $csock;

        print {$cw} $got;
        close $cw;

        exit;
    };

    close $cw;

    return ($path, $pr, $pid);
}

sub T2_escape {
    my $str = "épée";

    utf8::downgrade($str);

    my $escaped1 = Net::Curl::Easier->new()->escape($str);

    ok($escaped1, 'escape() returns something');

    utf8::upgrade($str);

    my $escaped2 = Net::Curl::Easier->new()->escape($str);

    is( $escaped1, $escaped2, 'escape() doesn’t care about internals' );

    return;
}

sub T15_lotta_stuff {
    my $self = shift;

    my ($sockpath, $sent_pipe, $pid) = _create_server(qr<thepostdata\z>);

    my $easy = Net::Curl::Easier->new(
        UNIX_SOCKET_PATH => $sockpath,
    );

    my $url = "http://localhost/épée";
    utf8::upgrade($url);

    is(
        $easy->set( url => $url, copypostfields => 'thepostdata' ),
        $easy,
        'set() returns $easy',
    );

    my $hdr = "X-épée: épée";
    utf8::upgrade($hdr);

    is(
        $easy->push( httpheader => [$hdr, "X-¡hola: ¡hola"] ),
        $easy,
        'push() returns $easy',
    );

    $easy->pushopt(
        Net::Curl::Easy::CURLOPT_HTTPHEADER,
        [ do { utf8::upgrade( my $v = "X-Käse: Käse" ); $v } ],
    );

    $easy->setopt(
        Net::Curl::Easy::CURLOPT_USERAGENT,
        do { utf8::upgrade( my $ua = "Très-Bien" ); $ua },
    );

    is(
        dies {
            $easy->set(
                useragent => 'not the real thing',
                asdfasgagda => 'hey hey',
            );
        },
        check_set(
            match( qr<ASDFASGAGDA> ),
            not_in_set( match( qr<Easier\.pm> ) ),
        ),
        'set() when given an invalid argument',
    );

    is(
        dies {
            $easy->push(
                httpheader => ['Not: Real'],
                asdfasgagda => 'hey hey',
            );
        },
        check_set(
            match( qr<ASDFASGAGDA> ),
            not_in_set( match( qr<Easier\.pm> ) ),
        ),
        'set() when given an invalid argument',
    );

    is( $easy->perform(), $easy, 'perform() returns the object' );

    my $sent = do { local $/; <$sent_pipe> };

    waitpid $pid, 0;

    is($easy->body(), 'hello', 'body() as expected');
    like( $easy->head(), qr<\AHTTP/.+\x0d\x0a\x0d\x0a\z>s, 'head() as expected' );

    like($sent, qr<X-épée:\s+épée>, 'header via push()');
    like($sent, qr<X-¡hola:\s+¡hola>, 'header via push() (again)');
    like($sent, qr<X-Käse:\s+Käse>, 'header via pushopt()');
    like($sent, qr<User-Agent: Très-Bien>, 'setopt(CURLOPT_USERAGENT) (and set() with invalid item doesn’t clobber)');
    unlike($sent, qr<Not: Real>, 'push() with invalid item doesn’t go in' );

    like( $easy->get('effective_url'), qr<localhost>, 'get()' );

    is(
        dies { $easy->get('asdfasgagda') },
        check_set(
            match( qr<ASDFASGAGDA> ),
            not_in_set( match( qr<Easier\.pm> ) ),
        ),
        'get() when given an invalid argument',
    );

    is(
        dies { $easy->send('haha') },
        object {
            prop blessed => 'Net::Curl::Easy::Code',
        },
        'send() throws on HTTP',
    );

    return;
}

sub T1_strerror {
    is(
        Net::Curl::Easier::strerror(0),
        Net::Curl::Easy::strerror(0),
        'strerror',
    );
}

sub T1_isa {
    isa_ok( 'Net::Curl::Easier', 'Net::Curl::Easy' );
}

1;
