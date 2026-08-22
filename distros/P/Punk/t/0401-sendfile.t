#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Test;
use Scalar::Util ();

# $c->send_file end to end: the whole download story - validators, ranges,
# disposition, HEAD, both sources - through the compiled dispatcher.

my $dir   = File::Temp->newdir;
my $bytes = join '', map chr($_ % 256), 0 .. 99_999;   # binary, > one chunk
my $path  = "$dir/fixture.pdf";
open my $fh, '>', $path or die "fixture: $!";
binmode $fh;
print {$fh} $bytes;
close $fh;

my $small = "0123456789" x 10;                          # 100 bytes
my $spath = "$dir/small.txt";
open $fh, '>', $spath or die "fixture: $!";
print {$fh} $small;
close $fh;

{
    package My::SendFile::App;
    use Punk;

    any '/file'    => sub { $_[0]->send_file($path) };
    any '/small'   => sub { $_[0]->send_file($spath) };
    any '/named'   => sub { $_[0]->send_file($spath,
                                filename => 'report.txt') };
    any '/utf8'    => sub { $_[0]->send_file($spath,
                                filename => "b\x{fc}cher.txt",
                                inline   => 1) };
    any '/typed'   => sub { $_[0]->send_file($spath,
                                type => 'text/x-fixture') };
    any '/frozen'  => sub { $_[0]->send_file($spath,
                                ranges => 0) };
    any '/tagged'  => sub { $_[0]->send_file($spath,
                                etag => 'v7') };
    any '/fresh'   => sub { $_[0]->send_file($spath,
                                cache_control => 'private, max-age=600') };
    any '/mem'     => sub { my $b = $small; $_[0]->send_file(\$b) };
    any '/mem-t'   => sub { my $b = $small;
                            $_[0]->send_file(\$b,
                                type  => 'text/plain',
                                mtime => 1000000) };
    any '/gone'    => sub { $_[0]->send_file("$dir/absent.bin",
                                missing => 'not_found') };
    any '/croaks'  => sub { $_[0]->send_file("$dir/absent.bin") };
    any '/extra'   => sub { my $c = shift;
                            $c->header('X-Download' => 'yes');
                            $c->send_file($spath) };
}

my $t = Punk::Test->new('My::SendFile::App');

# ---- the plain 200 -----------------------------------------------------------

$t->get_ok('/file')->status_is(200)
  ->header_is('Content-Type'   => 'application/pdf')
  ->header_is('Content-Length' => length $bytes)
  ->header_is('Accept-Ranges'  => 'bytes')
  ->content_is($bytes);
like $t->header('ETag'), qr/^"[0-9a-f]+-[0-9a-f]+"$/, 'strong hex ETag';
like $t->header('Last-Modified'), qr/GMT$/, 'Last-Modified is an HTTP date';
ok !defined $t->header('Content-Disposition'),
    'no disposition unless asked for';

my $etag = $t->header('ETag');
my $date = $t->header('Last-Modified');

# ---- HEAD --------------------------------------------------------------------

$t->head_ok('/file')->status_is(200)
  ->header_is('Content-Length' => length $bytes)
  ->content_is('');

# HEAD never gets a range
$t->head_ok('/file', headers => { Range => 'bytes=0-9' })->status_is(200)
  ->header_is('Content-Length' => length $bytes);
ok !defined $t->header('Content-Range'), 'no Content-Range on HEAD';

# ---- ranges ------------------------------------------------------------------

$t->get_ok('/file', headers => { Range => 'bytes=0-9' })->status_is(206)
  ->header_is('Content-Range'  => 'bytes 0-9/' . length $bytes)
  ->header_is('Content-Length' => 10)
  ->content_is(substr $bytes, 0, 10);

$t->get_ok('/file', headers => { Range => 'bytes=70000-70009' })
  ->status_is(206)
  ->content_is(substr $bytes, 70000, 10);

# a range wider than one 64KB reader chunk arrives whole and exact
$t->get_ok('/file', headers => { Range => 'bytes=1000-99000' })
  ->status_is(206)
  ->header_is('Content-Length' => 98001)
  ->content_is(substr $bytes, 1000, 98001);

$t->get_ok('/file', headers => { Range => 'bytes=-10' })->status_is(206)
  ->header_is('Content-Range' =>
      'bytes ' . (length($bytes) - 10) . '-' . (length($bytes) - 1)
               . '/' . length $bytes)
  ->content_is(substr $bytes, -10);

$t->get_ok('/file', headers => { Range => 'bytes=99990-' })->status_is(206)
  ->content_is(substr $bytes, 99990);

# unsatisfiable
$t->get_ok('/file', headers => { Range => 'bytes=999999-' })->status_is(416)
  ->header_is('Content-Range'  => 'bytes */' . length $bytes)
  ->header_is('Content-Length' => 0)
  ->content_is('');

# multi-range and malformed both legally collapse to the full 200
$t->get_ok('/file', headers => { Range => 'bytes=0-1,5-9' })->status_is(200)
  ->content_is($bytes);
$t->get_ok('/file', headers => { Range => 'chapters=1-2' })->status_is(200)
  ->content_is($bytes);

# Range applies to GET alone
$t->post_ok('/file', headers => { Range => 'bytes=0-9' })->status_is(200)
  ->header_is('Content-Length' => length $bytes);

# ---- If-Range ----------------------------------------------------------------

$t->get_ok('/file', headers => { Range => 'bytes=0-9', 'If-Range' => $etag })
  ->status_is(206, 'If-Range with the current ETag keeps the range');
$t->get_ok('/file', headers => { Range    => 'bytes=0-9',
                                 'If-Range' => '"stale-0"' })
  ->status_is(200, 'a stale If-Range falls back to the full body')
  ->content_is($bytes);
$t->get_ok('/file', headers => { Range => 'bytes=0-9', 'If-Range' => $date })
  ->status_is(206, 'If-Range takes the exact date too');
$t->get_ok('/file', headers => { Range    => 'bytes=0-9',
                                 'If-Range' => 'W/' . $etag })
  ->status_is(200, 'a weak tag never matches If-Range');

# ---- conditional GET -----------------------------------------------------------

$t->get_ok('/file', headers => { 'If-None-Match' => $etag })->status_is(304)
  ->header_is(ETag => $etag)
  ->content_is('');
$t->get_ok('/file', headers => { 'If-None-Match' => '"other", ' . $etag })
  ->status_is(304, 'the tag is found in a list');
$t->get_ok('/file', headers => { 'If-None-Match' => '*' })->status_is(304);
$t->get_ok('/file', headers => { 'If-Modified-Since' => $date })
  ->status_is(304);
$t->get_ok('/file', headers => { 'If-None-Match'     => '"other"',
                                 'If-Modified-Since' => $date })
  ->status_is(200, 'If-None-Match wins over If-Modified-Since');

# ---- disposition ---------------------------------------------------------------

$t->get_ok('/named')->status_is(200)
  ->header_is('Content-Disposition' => 'attachment; filename="report.txt"');
$t->get_ok('/utf8')->status_is(200)
  ->header_is('Content-Disposition' =>
      q{inline; filename="b__cher.txt"; filename*=UTF-8''b%C3%BCcher.txt});

# ---- options -------------------------------------------------------------------

$t->get_ok('/typed')->header_is('Content-Type' => 'text/x-fixture');
$t->get_ok('/small')->header_is('Content-Type' => 'text/plain; charset=utf-8');

$t->get_ok('/frozen')->status_is(200);
ok !defined $t->header('Accept-Ranges'), 'ranges => 0 stops advertising';
$t->get_ok('/frozen', headers => { Range => 'bytes=0-9' })->status_is(200)
  ->content_is($small);

$t->get_ok('/tagged')->header_is(ETag => '"v7"');
$t->get_ok('/tagged', headers => { 'If-None-Match' => '"v7"' })
  ->status_is(304, 'the etag override drives the conditional');

# ---- freshness ------------------------------------------------------------------

$t->get_ok('/fresh')->status_is(200)
  ->header_is('Cache-Control' => 'private, max-age=600');
# and on the 304: a stored response whose lifetime has just run out needs it
# renewed, or the header buys exactly one hit
$t->get_ok('/fresh', headers => { 'If-None-Match' => $t->header('ETag') })
  ->status_is(304)
  ->header_is('Cache-Control' => 'private, max-age=600');
$t->get_ok('/small')->status_is(200);
ok !defined $t->header('Cache-Control'),
   'a send_file that was told nothing still sends no Cache-Control';

# ---- the in-memory source -------------------------------------------------------

$t->get_ok('/mem')->status_is(200)
  ->header_is('Content-Type'   => 'application/octet-stream')
  ->header_is('Content-Length' => 100)
  ->content_is($small);
ok !defined $t->header('Last-Modified'), 'no mtime, no Last-Modified';
ok !defined $t->header('ETag'),          'no validator to build one from';

$t->get_ok('/mem', headers => { Range => 'bytes=10-19' })->status_is(206)
  ->header_is('Content-Range' => 'bytes 10-19/100')
  ->content_is('0123456789');

$t->get_ok('/mem-t')->header_is('Content-Type' => 'text/plain');
ok defined $t->header('Last-Modified'), 'mtime option brings the validator';
my $mem_etag = $t->header('ETag');
$t->get_ok('/mem-t', headers => { 'If-None-Match' => $mem_etag })
  ->status_is(304);

# ---- missing files ---------------------------------------------------------------

$t->get_ok('/gone')->status_is(404)
  ->header_is('Content-Type' => 'application/json')
  ->json_is('/errors/0/message' => 'Not Found');
$t->get_ok('/croaks')->status_is(500, 'default missing behaviour dies');

# ---- $c->header pairs ride along --------------------------------------------------

$t->get_ok('/extra')->status_is(200)
  ->header_is('X-Download' => 'yes');
$t->get_ok('/extra', headers => { Range => 'bytes=0-9' })->status_is(206)
  ->header_is('X-Download' => 'yes');

# ---- the reader's fileno, which is a contract with the server ---------------
# Everything above reads a ranged body through getline. Hyperman 0.20+ does
# not: it takes `fileno` and the Content-Length and sends the window straight
# from the file, never calling getline at all. So the load-bearing claim is
# that the descriptor's CURRENT POSITION is the start of the range - and
# nothing checked it, because the test client always consumes the body the
# other way.
#
# It has to go through a raw PSGI call rather than the client above: the test
# client consumes a getline body to give you a string, so by the time it has a
# response there is no unconsumed reader left to ask.
{
    my $app = $t->{app};          # already compiled by the client above
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/file',
                     QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                     'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                     'psgi.errors' => \*STDERR,
                     HTTP_RANGE => 'bytes=70000-70009' });
    is($r->[0], 206, 'a ranged request answers 206');
    my $body = $r->[2];

    SKIP: {
        skip 'this ranged body is not a Reader', 4
            unless Scalar::Util::blessed($body)
               && $body->isa('Punk::SendFile::Reader');

        my $fd = $body->fileno;
        cmp_ok($fd, '>=', 0, 'a ranged body hands the server a real descriptor');

        # read from the fd itself, the way a server sending natively would
        open my $dup, '<&=', $fd or die "dup: $!";
        binmode $dup;
        read $dup, my $window, 10;
        is($window, substr($bytes, 70000, 10),
            'and its position is already at the START of the range - a server '
          . 'that trusted this and seeked nowhere sends the right bytes');

        $body->close;
        is($body->fileno, -1, 'fileno is -1 once closed');
        is($body->getline, undef, 'and getline is spent');
    }
}

done_testing;
