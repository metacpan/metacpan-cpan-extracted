use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Warn;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

my $hello_etag          = etag('hello.txt');
my $hello_last_modified = last_modified('hello.txt');

my ($goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip) = etag('goodbye.txt', 'br', 'gzip');
my $goodbye_last_modified = last_modified('goodbye.txt');

my $t = Test::Mojo->new;

# hello.txt has no compressed files
$t->get_ok('/hello.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $hello_etag)
    ->header_is('Last-Modified' => $hello_last_modified)
    ->content_is("Hello Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye.txt')->status_is(200)->content_type_is('text/plain;charset=UTF-8')
    ->header_is(ETag => $goodbye_etag)->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => ''})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'nothing'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'gzip, br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

# test when file is dir
my $tmpdir = Mojo::File::tempdir();
push @{app->static->paths}, $tmpdir;

Mojo::File->new("$tmpdir/basic_dir.txt")->spurt('Hello from the dir file!');
my ($dir_etag, $dir_etag_gzip) = etag(app->static, 'basic_dir.txt', 'gzip');
my $dir_last_modified = last_modified(app->static, 'basic_dir.txt');
my $dir_gzip_path     = "$tmpdir/basic_dir.txt.gz";
mkdir "$dir_gzip_path" or die 'failed to make dir';
$t->get_ok('/basic_dir.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $dir_etag)
    ->header_is('Last-Modified' => $dir_last_modified)->content_is('Hello from the dir file!');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test when we cannot read compressed asset path
# first, test that we can read it
Mojo::File->new("$tmpdir/basic_unreadable.txt")->spurt('Hello from the uncompressed file!');
my $unreadable_compressed_file
    = Mojo::File->new("$tmpdir/basic_unreadable.txt.gz")->spurt('Hello from the compressed file!');

my ($unreadable_etag, $unreadable_etag_gzip) = etag(app->static, 'basic_unreadable.txt', 'gzip');
my $unreadable_last_modified = last_modified(app->static, 'basic_unreadable.txt');
$t->get_ok('/basic_unreadable.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag            => $unreadable_etag_gzip)
    ->header_is('Last-Modified' => $unreadable_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('Hello from the compressed file!');

# make compressed file unreadable
$unreadable_compressed_file->chmod(0000);
my $unreadable_compressed_path = $unreadable_compressed_file->path;
$t->get_ok('/basic_unreadable.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $unreadable_etag)
    ->header_is('Last-Modified' => $unreadable_last_modified)
    ->content_is('Hello from the uncompressed file!');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# make file readable again and test that it works, then delete and test that we get warning
$unreadable_compressed_file->chmod(0777);
$t->get_ok('/basic_unreadable.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag            => $unreadable_etag_gzip)
    ->header_is('Last-Modified' => $unreadable_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('Hello from the compressed file!');

unlink $unreadable_compressed_path;
$t->get_ok('/basic_unreadable.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $unreadable_etag)
    ->header_is('Last-Modified' => $unreadable_last_modified)
    ->content_is('Hello from the uncompressed file!');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test when compressed files are the same size that they are not used
my $compressed_same_size_etag          = etag('compressed_same_size.txt');
my $compressed_same_size_last_modified = last_modified('compressed_same_size.txt');
my $same_size_path                     = app->static->file('compressed_same_size.txt')->path;
my $same_size_br_path                  = "$same_size_path.br";
my $same_size_gzip_path                = "$same_size_path.gz";
warnings_like {
    $t->get_ok('/compressed_same_size.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
        ->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag            => $compressed_same_size_etag)
        ->header_is('Last-Modified' => $compressed_same_size_last_modified)->content_is("aaaa\n");
}
[   qr/Compressed asset \Q$same_size_br_path\E is 5 bytes, and uncompressed asset \Q$same_size_path\E is 5 bytes\. Continuing search for compressed assets\./,
    qr/Compressed asset \Q$same_size_gzip_path\E is 5 bytes, and uncompressed asset \Q$same_size_path\E is 5 bytes\. Continuing search for compressed assets\./,
],
    'compressed files that are the same size are not used and emit a warning';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test compressed files that are one byte larger are not used
my $compressed_one_larger_etag          = etag('compressed_one_larger.txt');
my $compressed_one_larger_last_modified = last_modified('compressed_one_larger.txt');
my $one_larger_path                     = app->static->file('compressed_one_larger.txt')->path;
my $one_larger_br_path                  = "$one_larger_path.br";
my $one_larger_gzip_path                = "$one_larger_path.gz";
warnings_like {
    $t->get_ok('/compressed_one_larger.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
        ->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag            => $compressed_one_larger_etag)
        ->header_is('Last-Modified' => $compressed_one_larger_last_modified)->content_is("aaaa\n");
}
[   qr/Compressed asset \Q$one_larger_br_path\E is 6 bytes, and uncompressed asset \Q$one_larger_path\E is 5 bytes\. Continuing search for compressed assets\./,
    qr/Compressed asset \Q$one_larger_gzip_path\E is 6 bytes, and uncompressed asset \Q$one_larger_path\E is 5 bytes\. Continuing search for compressed assets\./,
],
    'compressed files that are the one byte larger are not used and emit a warning';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test compressed files that are one byte smaller are used
my ($compressed_one_smaller_etag,
    $compressed_one_smaller_etag_br,
    $compressed_one_smaller_etag_gzip
) = etag('compressed_one_smaller.txt', 'br', 'gzip');
my $compressed_one_smaller_last_modified = last_modified('compressed_one_smaller.txt');
$t->get_ok('/compressed_one_smaller.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag            => $compressed_one_smaller_etag_br)
    ->header_is('Last-Modified' => $compressed_one_smaller_last_modified)
    ->header_is(Vary            => 'Accept-Encoding')->content_is("bbb\n");

$t->get_ok('/compressed_one_smaller.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag            => $compressed_one_smaller_etag_gzip)
    ->header_is('Last-Modified' => $compressed_one_smaller_last_modified)
    ->header_is(Vary            => 'Accept-Encoding')->content_is("ccc\n");

done_testing;
