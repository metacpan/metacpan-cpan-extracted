use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Warn;
use Mojolicious::Lite;
use Mojo::File ();
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

my ($hello_etag, $hello_etag_br, $hello_etag_deflate) = etag('hello.txt', 'br', 'deflate');
my $hello_last_modified = last_modified('hello.txt');

my ($goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip, $goodbye_etag_deflate)
    = etag('goodbye.txt', 'br', 'gzip', 'deflate');
my $goodbye_last_modified = last_modified('goodbye.txt');

my $t = Test::Mojo->new;

# non-compressed etag uses non-compressed asset to determine if file has changed
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $goodbye_etag})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)->content_is('');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# using br etag returns 304
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $goodbye_etag_br})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'br')->header_is(ETag => $goodbye_etag_br)
    ->header_is('Last-Modified' => $goodbye_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

# using gzip etag returns 304
$t->get_ok(
    '/goodbye.txt' => {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $goodbye_etag_gzip})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'gzip')->header_is(ETag => $goodbye_etag_gzip)
    ->header_is('Last-Modified' => $goodbye_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

# larger_compressed.txt returns 304 for compressed assets that are larger
my (undef, $larger_compressed_etag_br, $larger_compressed_etag_gzip)
    = etag('larger_compressed.txt', 'br', 'gzip');
my $larger_compressed_last_modified = last_modified('larger_compressed.txt');
$t->get_ok('/larger_compressed.txt' =>
        {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $larger_compressed_etag_br})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'br')->header_is(ETag => $larger_compressed_etag_br)
    ->header_is('Last-Modified' => $larger_compressed_last_modified)
    ->header_is(Vary            => 'Accept-Encoding')->content_is('');

$t->get_ok('/larger_compressed.txt' =>
        {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $larger_compressed_etag_gzip})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'gzip')->header_is(ETag => $larger_compressed_etag_gzip)
    ->header_is('Last-Modified' => $larger_compressed_last_modified)
    ->header_is(Vary            => 'Accept-Encoding')->content_is('');

# test invalid compression type falls back to br
warning_like {
    $t->get_ok('/goodbye.txt' =>
            {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $goodbye_etag_deflate})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is('Content-Encoding' => 'br')->header_is(ETag => $goodbye_etag_br)
        ->header_is('Last-Modified'    => $goodbye_last_modified)
        ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n")
}
qr/Found expected compression encoding of 'deflate' in If-None-Match '$goodbye_etag_deflate' for asset '.*?goodbye.txt', but encoding does not exist\./,
    'non-existent encoding type falls back to br compressed file';

# test invalid compression type falls back to gzip
warning_like {
    $t->get_ok(
        '/goodbye.txt' => {'Accept-Encoding' => 'gzip', 'If-None-Match' => $goodbye_etag_deflate})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is('Content-Encoding' => 'gzip')->header_is(ETag => $goodbye_etag_gzip)
        ->header_is('Last-Modified'    => $goodbye_last_modified)
        ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n")
}
qr/Found expected compression encoding of 'deflate' in If-None-Match '$goodbye_etag_deflate' for asset '.*?goodbye.txt', but encoding does not exist\./,
    'non-existent encoding type falls back to gzip compressed file';

# test invalid compression type falls back to uncompressed file
warning_like {
    $t->get_ok(
        '/hello.txt' => {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $hello_etag_deflate})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag => $hello_etag)->header_is('Last-Modified' => $hello_last_modified)
        ->content_is("Hello Mojo from a static file!\n")
}
qr/Found expected compression encoding of 'deflate' in If-None-Match '$hello_etag_deflate' for asset '.*?hello.txt', but encoding does not exist\./,
    'non-existent encoding type falls back to uncompressed file';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test when file does not exist
my $hello_br_path = app->static->file('hello.txt')->path . '.br';
warning_like {
    $t->get_ok('/hello.txt' => {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $hello_etag_br})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag => $hello_etag)->header_is('Last-Modified' => $hello_last_modified)
        ->content_is("Hello Mojo from a static file!\n")
}
qr/Found compression type with encoding of br in If-None-Match '$hello_etag_br', but asset at \Q$hello_br_path\E does not exist, is a directory, or is unreadable\./,
    'non-existent file falls back to uncompressed file';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test when file is dir
my $tmpdir = Mojo::File::tempdir();
push @{app->static->paths}, $tmpdir;

Mojo::File->new("$tmpdir/if_none_match_dir.txt")->spurt('Hello from the dir file!');
my ($dir_etag, $dir_etag_gzip) = etag(app->static, 'if_none_match_dir.txt', 'gzip');
my $dir_last_modified = last_modified(app->static, 'if_none_match_dir.txt');
my $dir_gzip_path     = "$tmpdir/if_none_match_dir.txt.gz";
mkdir "$dir_gzip_path" or die 'failed to make dir';
warning_like {
    $t->get_ok('/if_none_match_dir.txt' =>
            {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $dir_etag_gzip})->status_is(200)
        ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $dir_etag)
        ->header_is('Last-Modified' => $dir_last_modified)->content_is('Hello from the dir file!')
}
qr/Found compression type with encoding of gzip in If-None-Match '$dir_etag_gzip', but asset at \Q$dir_gzip_path\E does not exist, is a directory, or is unreadable\./,
    'directory falls back to uncompressed file';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test when we cannot read compressed asset path
# first, test that we can read it
Mojo::File->new("$tmpdir/if_none_match_unreadable.txt")->spurt('Hello from the uncompressed file!');
my $unreadable_compressed_file = Mojo::File->new("$tmpdir/if_none_match_unreadable.txt.gz")
    ->spurt('Hello from the compressed file!');

my ($unreadable_etag, $unreadable_etag_gzip)
    = etag(app->static, 'if_none_match_unreadable.txt', 'gzip');
my $unreadable_last_modified = last_modified(app->static, 'if_none_match_unreadable.txt');
$t->get_ok('/if_none_match_unreadable.txt' =>
        {'Accept-Encoding' => 'gzip', 'If-None-Match' => $unreadable_etag_gzip})->status_is(304)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag            => $unreadable_etag_gzip)
    ->header_is('Last-Modified' => $unreadable_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

# make compressed file unreadable
$unreadable_compressed_file->chmod(0000);
my $unreadable_compressed_path = $unreadable_compressed_file->path;
warning_like {
    $t->get_ok('/if_none_match_unreadable.txt' =>
            {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $unreadable_etag_gzip})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag            => $unreadable_etag)
        ->header_is('Last-Modified' => $unreadable_last_modified)
        ->content_is('Hello from the uncompressed file!')
}
qr/Found compression type with encoding of gzip in If-None-Match '$unreadable_etag_gzip', but asset at \Q$unreadable_compressed_path\E does not exist, is a directory, or is unreadable\./,
    'unreadable file falls back to uncompressed file';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# make file readable again and test that it works, then delete and test that we get warning
$unreadable_compressed_file->chmod(0777);
$t->get_ok('/if_none_match_unreadable.txt' =>
        {'Accept-Encoding' => 'gzip', 'If-None-Match' => $unreadable_etag_gzip})->status_is(304)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag            => $unreadable_etag_gzip)
    ->header_is('Last-Modified' => $unreadable_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

unlink $unreadable_compressed_path;
warning_like {
    $t->get_ok('/if_none_match_unreadable.txt' =>
            {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => $unreadable_etag_gzip})
        ->status_is(200)->content_type_is('text/plain;charset=UTF-8')
        ->header_is(ETag            => $unreadable_etag)
        ->header_is('Last-Modified' => $unreadable_last_modified)
        ->content_is('Hello from the uncompressed file!')
}
qr/Found compression type with encoding of gzip in If-None-Match '$unreadable_etag_gzip', but asset at \Q$unreadable_compressed_path\E does not exist, is a directory, or is unreadable\./,
    'unreadable file falls back to uncompressed file';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test that first match is used
$t->get_ok(
    '/goodbye.txt' => {
        'Accept-Encoding' => 'br, gzip',
        'If-None-Match'   => "$goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip"
    }
)->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is(ETag => $goodbye_etag)->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is('');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# using br etag returns 304
$t->get_ok(
    '/goodbye.txt' => {
        'Accept-Encoding' => 'br, gzip',
        'If-None-Match'   => "$goodbye_etag_br, $goodbye_etag_gzip, $goodbye_etag"
    }
)->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'br')->header_is(ETag => $goodbye_etag_br)
    ->header_is('Last-Modified' => $goodbye_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

# using gzip etag returns 304
$t->get_ok(
    '/goodbye.txt' => {
        'Accept-Encoding' => 'br, gzip',
        'If-None-Match'   => "$goodbye_etag_gzip, $goodbye_etag, $goodbye_etag_br"
    }
)->status_is(304)->content_type_is('text/plain;charset=UTF-8')
    ->header_is('Content-Encoding' => 'gzip')->header_is(ETag => $goodbye_etag_gzip)
    ->header_is('Last-Modified' => $goodbye_last_modified)->header_is(Vary => 'Accept-Encoding')
    ->content_is('');

# test that non-existent encodings and non-existent files fall back to legitemate compressed file
my (undef, $hola_etag_br, $hola_etag_gzip, $hola_etag_deflate)
    = etag('hola.txt', 'br', 'gzip', 'deflate');
my $hola_last_modified = last_modified('hola.txt');
my $hola_gzip_path     = app->static->file('hola.txt')->path . '.gz';    # does not exist
warnings_like {
    $t->get_ok(
        '/hola.txt' => {
            'Accept-Encoding' => 'br, gzip',
            'If-None-Match'   => "$hola_etag_deflate, $hola_etag_gzip, $hola_etag_br"
        }
    )->status_is(304)->content_type_is('text/plain;charset=UTF-8')
        ->header_is('Content-Encoding' => 'br')->header_is(ETag => $hola_etag_br)
        ->header_is('Last-Modified' => $hola_last_modified)->header_is(Vary => 'Accept-Encoding')
        ->content_is('');
}
[   qr/Found expected compression encoding of 'deflate' in If-None-Match '$hola_etag_deflate' for asset '.*?hola.txt', but encoding does not exist\./,
    qr/Found compression type with encoding of gzip in If-None-Match '$hola_etag_gzip', but asset at \Q$hola_gzip_path\E does not exist, is a directory, or is unreadable\./
],
    'non-existent compression encodings and then non-existent compressed files fall back to legitemate compressed file';

# test that whitespace doesn't matter
# test with one if-none-match
$t->get_ok('/goodbye.txt' =>
        {'Accept-Encoding' => 'br, gzip', 'If-None-Match' => "    $goodbye_etag     "})
    ->status_is(304)->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)->content_is('');
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test with multiple if-none-match
warnings_like {
    $t->get_ok(
        '/hola.txt' => {
            'Accept-Encoding' => 'br, gzip',
            'If-None-Match'   => "   $hola_etag_deflate  , $hola_etag_gzip   , $hola_etag_br  "
        }
    )->status_is(304)->content_type_is('text/plain;charset=UTF-8')
        ->header_is('Content-Encoding' => 'br')->header_is(ETag => $hola_etag_br)
        ->header_is('Last-Modified' => $hola_last_modified)->header_is(Vary => 'Accept-Encoding')
        ->content_is('');
}
[   qr/Found expected compression encoding of 'deflate' in If-None-Match '$hola_etag_deflate' for asset '.*?hola.txt', but encoding does not exist\./,
    qr/Found compression type with encoding of gzip in If-None-Match '$hola_etag_gzip', but asset at \Q$hola_gzip_path\E does not exist, is a directory, or is unreadable\./
],
    q{whitespace doesn't matter for multiple if-none-match};

done_testing;
