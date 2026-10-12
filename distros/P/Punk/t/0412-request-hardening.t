#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk ();

# What a request may cost: an upload refused part way, a body whose declared
# length is a lie, an origin asked for many times, a header built from input.

my $DIR = File::Temp::tempdir(CLEANUP => 1);
my $B   = '----PunkH';

sub rss {
    return undef if $^O eq 'MSWin32';
    my ($n) = (`ps -o rss= -p $$` // '') =~ /(\d+)/;
    return $n;
}
sub fds { my @f = glob '/dev/fd/*'; return scalar @f }
sub leftovers { my @f = glob "$DIR/punk-up-*"; return scalar @f }

sub part {
    my (%p) = @_;
    my $out = qq{--$B\r\nContent-Disposition: form-data; name="$p{name}"};
    $out .= qq{; filename="$p{filename}"} if defined $p{filename};
    return "$out\r\n\r\n$p{data}\r\n";
}
sub multipart { return join('', map { part(%$_) } @_) . "--$B--\r\n" }

sub post {
    my ($app, $path, $body, %o) = @_;
    open my $fh, '<', \$body or die $!;
    my $res = eval { $app->({
        REQUEST_METHOD => 'POST', PATH_INFO => $path, QUERY_STRING => '',
        CONTENT_TYPE   => $o{type} // "multipart/form-data; boundary=$B",
        ($o{no_length} ? () : (CONTENT_LENGTH => $o{length} // length $body)),
        'psgix.input.buffered' => 1,
        'psgi.input' => $fh, 'psgi.errors' => \*STDERR,
        HTTP_HOST => 'example.com', 'psgi.url_scheme' => 'https',
        %{ $o{env} || {} },
    }) };
    return $res;
}
sub text { my ($r) = @_; return ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '' }

{
    package Hard;
    use Punk;
    upload_dir $DIR;
    host 'https://example.com';
    post '/u' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('f');
        $c->text(join ',', ($up ? $up->size : -1), ($c->param('n') // '-'));
    }, { max_body => 200_000 };
    post '/names' => sub {
        my ($c) = @_;
        $c->json([ map { $_->basename } @{ $c->req->uploads->{f} } ]);
    };
    post '/body' => sub {
        my ($c) = @_;
        my $b = $c->req->body // '';
        require Digest::MD5;
        $c->text(length($b) . ':' . Digest::MD5::md5_hex($b));
    };
    get '/origin' => sub {
        my ($c) = @_;
        my $o;
        $o = $c->origin for 1 .. ($c->param('n') || 1);
        $c->text($o);
    };
    get '/header' => sub {
        my ($c) = @_;
        my $what = $c->param('what') // 'value';
        my $v = $c->param('v');
        my $ok = eval {
            $what eq 'name' ? $c->header($v => 'x') : $c->header('X-Echo' => $v);
            1;
        };
        return $c->text("refused: $@") unless $ok;
        $c->text('set');
    };
}
my $app = Hard->to_app;

# ---- an upload refused part way leaves nothing ---------------------------------
# No Content-Length is the HTTP/2 and HTTP/3 upload: nothing can refuse it up
# front, so the walk reads until the route's ceiling stops it, mid-part.
{
    my $file  = multipart({ name => 'f', filename => 'a.bin', data => 'x' x 300_000 });
    my $field = multipart({ name => 'n', data => 'y' x 190_000 },
                          { name => 'm', data => 'z' x 50_000 });
    my $mixed = multipart({ name => 'n', data => 'ok' },
                          { name => 'f', filename => 'a.bin', data => 'x' x 100_000 },
                          { name => 'g', filename => 'b.bin', data => 'x' x 300_000 });

    my $r = post($app, '/u', $file, no_length => 1);
    is $r->[0], 500, 'an undeclared upload past the ceiling is refused';
    like text($r), qr/the ceiling this read was given/, '...by the ceiling';
    is leftovers(), 0, '...and its half-written temp file is gone';

    $r = post($app, '/u', $mixed, no_length => 1);
    is $r->[0], 500, 'refused in a later part';
    is leftovers(), 0, '...the finished part\'s temp file goes too';

  SKIP: {
        skip 'no /dev/fd here', 2 unless -d '/dev/fd';
        post($app, '/u', $file, no_length => 1) for 1 .. 3;
        my $before = fds();
        post($app, '/u', $file, no_length => 1) for 1 .. 40;
        is fds(), $before, 'forty refused uploads leave no descriptor open';
        is leftovers(), 0, '...and no file';
    }
  SKIP: {
        skip 'no ps -o rss here', 2 unless defined rss();
        post($app, '/u', $field, no_length => 1) for 1 .. 30;
        my $before = rss();
        post($app, '/u', $field, no_length => 1) for 1 .. 200;
        my $grew = rss() - $before;
        cmp_ok $grew, '<', 8_000,
            "200 refused field parts grow the process by ${grew}KB, not 40MB";
        post($app, '/u', $file, no_length => 1) for 1 .. 30;
        $before = rss();
        post($app, '/u', $file, no_length => 1) for 1 .. 200;
        $grew = rss() - $before;
        cmp_ok $grew, '<', 8_000,
            "200 refused file parts grow it by ${grew}KB";
    }

    my $small = multipart({ name => 'n', data => 'v' },
                          { name => 'f', filename => 'a.bin', data => 'q' x 150_000 });
    $r = post($app, '/u', $small, no_length => 1);
    is $r->[0], 200, 'an upload under the ceiling still parses afterwards';
    is text($r), '150000,v', '...whole';
    is leftovers(), 0, '...and its temp file is removed with the request';
}

# ---- basename -------------------------------------------------------------------
{
    my @names = ('../../etc/cron.d/x', 'C:\\Users\\me\\photo.jpg', '.htaccess',
                 '...', "a\x01\x7fb.txt", 'plain.txt', 'dir/', '');
    my $body = multipart(map { { name => 'f', filename => $_, data => 'd' } } @names);
    my $r = post($app, '/names', $body);
    is text($r), '["x","photo.jpg","htaccess",null,"ab.txt","plain.txt",null,null]',
        'basename keeps the last segment, drops leading dots and control bytes';
}

# ---- a declared length is a claim -----------------------------------------------
{
    require Digest::MD5;
    # Forked: before the fix the largest of these did not fail, it took the
    # process with it.
    for my $claim (4_000_000_000, '4611686018427387904', '99999999999999999999') {
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd;
            close STDERR;
            my $r = post($app, '/body', 'abc', type => 'application/octet-stream',
                         length => $claim);
            print {$wr} $r ? "$r->[0] " . text($r) : 'died';
            close $wr;
            require POSIX;
            POSIX::_exit(0);
        }
        close $wr;
        my $got = do { local $/; <$rd> };
        waitpid $pid, 0;
        is $? & 127, 0, "Content-Length: $claim over three bytes does not kill the worker";
        is $got, '200 3:' . Digest::MD5::md5_hex('abc'),
            '...and the body is the three bytes that arrived';
    }
    for my $n (0, 1, 65_535, 65_536, 65_537, 200_000, 1_500_000) {
        my $body = join '', map { chr(($_ * 7) % 251) } 1 .. $n;
        my $r = post($app, '/body', $body, type => 'application/octet-stream');
        is text($r), "$n:" . Digest::MD5::md5_hex($body),
            "a $n byte body is read whole and exact";
    }
    my $long = 'z' x 300_000;
    my $r = post($app, '/body', $long, type => 'application/octet-stream',
                 length => 100_000);
    is text($r), '100000:' . Digest::MD5::md5_hex('z' x 100_000),
        'a body longer than declared is read to the declared length';
    $r = post($app, '/body', $long, type => 'application/octet-stream',
              no_length => 1);
    is text($r), '300000:' . Digest::MD5::md5_hex($long),
        'an undeclared buffered body is read to its end';
}

# ---- asking for the origin costs nothing ----------------------------------------
{
    my $get = sub {
        my ($n, $host) = @_;
        open my $in, '<', \'';
        return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/origin',
                        QUERY_STRING => "n=$n", HTTP_HOST => $host,
                        'psgi.url_scheme' => 'https', 'psgi.input' => $in });
    };
    is text($get->(1, 'example.com')), 'https://example.com', 'the origin';
    is text($get->(1, 'EXAMPLE.com')), 'https://example.com', '...whatever the case';
  SKIP: {
        skip 'no ps -o rss here', 1 unless defined rss();
        $get->(20_000, 'example.com');
        my $before = rss();
        $get->(200_000, 'example.com');
        my $grew = rss() - $before;
        cmp_ok $grew, '<', 4_000,
            "200,000 origins grow the process by ${grew}KB, not 14MB";
    }
}

# ---- a header is one line ---------------------------------------------------------
{
    my $get = sub {
        my ($query) = @_;
        open my $in, '<', \'';
        return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/header',
                        QUERY_STRING => $query, HTTP_HOST => 'example.com',
                        'psgi.url_scheme' => 'https', 'psgi.input' => $in });
    };
    for my $case ([ 'v=a%0d%0aSet-Cookie:%20pwn=1', 'value', 'CRLF in a value' ],
                  [ 'v=a%0ab',                      'value', 'a bare LF' ],
                  [ 'v=a%0db',                      'value', 'a bare CR' ],
                  [ 'v=a%00b',                      'value', 'a NUL' ],
                  [ 'what=name&v=X-A%0d%0aX-B',     'name',  'CRLF in a name' ]) {
        my ($q, $which, $label) = @$case;
        my $r = $get->($q);
        like text($r), qr/\Arefused: Punk::Response: a header $which may not contain/,
            "$label is refused";
        my %h = @{ $r->[1] };
        ok !exists $h{'X-Echo'} && !grep({ /pwn|X-B/ } @{ $r->[1] }),
            '...and nothing of it reaches the response';
    }
    my $r = $get->('v=plain%20value%09ok');
    is text($r), 'set', 'an ordinary value, tab included, is set';
    is { @{ $r->[1] } }->{'X-Echo'}, "plain value\tok", '...as given';
}

done_testing;
