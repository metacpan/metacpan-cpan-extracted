#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Test;

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

done_testing;
