use v5.10; use strict; use warnings;
use Test::More;
use Socket;
use Proxy::Impersonate::Connection;

{
    package FramingMulti;
    sub new { bless { calls => 0, removed => 0 }, shift }
    sub add_streaming { my ($s, $h, $r, $cbs) = @_; $s->{calls}++; $s->{cbs} = $cbs }
    sub remove { $_[0]{removed}++; delete $_[0]{cbs} }
    sub resume {}
}

sub connection {
    my (%o) = @_;
    my $method = delete $o{method} // 'GET';
    my $version = delete $o{version} // 'HTTP/1.1';
    my $extra = delete $o{extra} // '';
    my $tail = delete $o{tail} // '';
    socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;
    $client->blocking(0); $server->blocking(0);
    my $m = FramingMulti->new;
    my $c = Proxy::Impersonate::Connection->new(fd => $server, multi => $m,
        make_handle => sub { bless {}, 'FramingHandle' }, %o);
    $c->{rbuf} = "$method http://example.com/ $version\r\nHost: example.com\r\n$extra\r\n$tail";
    $c->_process;
    return ($c, $m, $client);
}

sub drain {
    my ($s) = @_;
    my $out = '';
    while (my $n = sysread($s, my $buf, 65536)) { $out .= $buf }
    return $out;
}

sub respond {
    my ($c, $m, $s, $status, $headers, $body, $err) = @_;
    my $cbs = delete $m->{cbs};
    {
        local $c->{multi_state}{busy} = 1;
        $cbs->{on_headers}->($status, $headers);
        $cbs->{on_body}->($body) if defined $body && length $body;
        $cbs->{on_done}->($err);
    }
    EV::run(EV::RUN_NOWAIT);
    return drain($s);
}

{
    my ($c, $m, $s) = connection(version => 'HTTP/1.0');
    my $got = respond($c, $m, $s, 200, { 'content-encoding' => 'gzip' }, 'decoded');
    unlike($got, qr/transfer-encoding:/i, 'HTTP/1.0 never receives chunked framing');
    like($got, qr/connection: close\r\n/i, 'HTTP/1.0 decoded body is delimited by close');
    like($got, qr/\r\n\r\ndecoded\z/, 'HTTP/1.0 body has no chunk markers');
    ok($c->{_dead}, 'HTTP/1.0 closes after the complete decoded response');
}

{
    my ($c, $m, $s) = connection();
    my $got = respond($c, $m, $s, 200,
        { 'content-encoding' => 'gzip', 'content-length' => 123 }, 'decoded');
    like($got, qr/transfer-encoding: chunked\r\n/, 'decoded body uses chunked framing');
    unlike($got, qr/content-(?:encoding|length):/i, 'encoded metadata is removed');
    like($got, qr/\r\n\r\n7\r\ndecoded\r\n0\r\n\r\n\z/, 'decoded bytes and chunk terminator are exact');
    $c->_close;
}

{
    my ($c, $m, $s) = connection();
    my $got = respond($c, $m, $s, 200, { 'content-encoding' => 'gzip' }, 'partial', 'broken');
    unlike($got, qr/0\r\n\r\n\z/, 'a failed decoded transfer is never marked complete');
    ok($c->{_dead}, 'failed transfer closes');
}

for my $case (['HEAD', 200], ['GET', 204], ['GET', 205], ['GET', 304]) {
    my ($method, $status) = @$case;
    my ($c, $m, $s) = connection(method => $method);
    my $got = respond($c, $m, $s, $status, {}, 'must not appear');
    unlike($got, qr/must not appear|transfer-encoding|connection: close/i,
           "$method $status is bodyless and can keep the connection");
    like($got, qr/\r\n\r\n\z/, 'no body bytes follow the head');
    $c->_close;
}

for my $method ('HEAD', 'GET') {
    my ($c, $m, $s) = connection(method => $method);
    my $status = $method eq 'HEAD' ? 200 : 304;
    my $got = respond($c, $m, $s, $status, { 'content-length' => 123, 'content-encoding' => 'gzip' });
    unlike($got, qr/content-(?:length|encoding):/i, 'encoded metadata cannot corrupt cached decoded content');
    unlike($got, qr/transfer-encoding:/i, 'bodyless response needs no chunk framing');
    $c->_close;
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my ($c, $m, $s) = connection(on_response => sub {
        delete $_[0]{headers}{'x-original'};
        $_[0]{headers}{'set-cookie'}[0] = 'changed';
        die "after mutation\n";
    });
    my $got = respond($c, $m, $s, 200,
        { 'content-length' => 0, 'x-original' => 'yes', 'set-cookie' => ['a=1', 'b=2'] });
    like($got, qr/x-original: yes\r\n/, 'a dying response hook rolls back deletions');
    like($got, qr/set-cookie: a=1\r\n/, 'rollback includes repeated header values');
    like(join('', @warnings), qr/on_response died/, 'hook failure is reported');
    $c->_close;
}

for my $case ([200, 204], [204, 200]) {
    my ($before, $after) = @$case;
    my ($c, $m, $s) = connection(on_response => sub { $_[0]{status} = $after; return });
    my $got = respond($c, $m, $s, $before, { 'content-length' => 4 }, 'body');
    unlike($got, qr/\r\n\r\nbody/, 'status rewrite cannot leak a body into the next response');
    if ($after == 204) { unlike($got, qr/content-length:/i, '204 has no content-length') }
    else { like($got, qr/content-length: 0\r\n/, 'rewritten empty response has an exact length') }
    $c->_close;
}

{
    my ($c, $m, $s) = connection(on_response => sub {
        $_[0]{headers} = { 'Content-Length' => 900, 'Transfer-Encoding' => 'chunked',
            Connection => 'x-private', 'X-Private' => 'secret', 'X-Added' => 'yes' };
        return;
    });
    my $got = respond($c, $m, $s, 200, { 'content-length' => 4 }, 'body');
    like($got, qr/content-length: 4\r\n/i, 'framing is protected with conventional header casing');
    unlike($got, qr/900|transfer-encoding|x-private/i, 'hook hop headers are removed');
    like($got, qr/x-added: yes/i, 'ordinary hook headers survive');
    $c->_close;
}

for my $status (200, 204, 205, 304) {
    my ($c, $m, $s) = connection(method => $status == 200 ? 'HEAD' : 'GET',
        on_request => sub { return { status => $status,
            headers => { 'Content-Length' => 900, 'Transfer-Encoding' => 'chunked' }, body => 'body' } });
    my $got = drain($s);
    unlike($got, qr/\r\n\r\nbody|900|transfer-encoding/i, 'synthetic bodyless response is framed safely');
    like($got, qr/content-length: 0\r\n/i, 'synthetic 205 has zero length') if $status == 205;
    unlike($got, qr/content-length:/i, 'synthetic 304 cannot overwrite cached body length') if $status == 304;
    $c->_close;
}

for my $synthetic (0, 1) {
    my %o = $synthetic ? (on_request => sub { { body => 'done' } }) : ();
    my ($c, $m, $s) = connection(%o, extra => "Connection: keep-alive\r\nConnection: close\r\n",
        tail => "GET http://example.com/second HTTP/1.1\r\n\r\n");
    my $got = $synthetic ? drain($s)
        : respond($c, $m, $s, 200, { 'content-length' => 4 }, 'done');
    like($got, qr/connection: close/i, 'client close request is honored');
    ok($c->{_dead}, 'connection is closed after the response');
    is($m->{calls}, $synthetic ? 0 : 1, 'no queued request is forwarded after close');
}

{
    my $c;
    my ($conn, $m, $s) = connection(on_response => sub { $c->_close });
    $c = $conn;
    {
        local $c->{multi_state}{busy} = 1;
        my $cbs = $m->{cbs};
        $cbs->{on_headers}->(200, { 'content-length' => 4 });
        is($m->{removed}, 0, 'curl removal is deferred while callbacks run');
        is($cbs->{on_body}->('body'), 2, 'closing callback aborts further body delivery');
    }
    EV::run(EV::RUN_NOWAIT);
    is($m->{removed}, 1, 'curl removal runs after the callback unwinds');
    ok($c->{_dead}, 'deferred close completes');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my ($c, $m, $s) = connection(make_handle => sub { die "initialization failed\n" });
    like(drain($s), qr/\AHTTP\/1.1 502 /, 'handle creation failure returns 502');
    ok($c->{_dead}, 'failed handle creation closes cleanly');
}

{
    my ($c, $m, $s) = connection(on_request => sub { { body => "snowman \x{2603}" } });
    my $got = drain($s);
    like($got, qr/content-length: 11\r\n/, 'synthetic Unicode body has its encoded byte length');
    like($got, qr/snowman \xe2\x98\x83\z/, 'synthetic Unicode body is sent as UTF-8');
    $c->_close;
}

done_testing;
