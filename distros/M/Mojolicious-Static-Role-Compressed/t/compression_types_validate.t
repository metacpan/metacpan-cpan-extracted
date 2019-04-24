use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Exception;
use Mojolicious::Static;
use Mojo::Util ();
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types(undef) }
qr/compression_types requires an ARRAY ref/, 'undef compression_types throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types(0) }
qr/compression_types requires an ARRAY ref/, 'zero compression_types throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types('string') }
qr/compression_types requires an ARRAY ref/, 'string compression_types throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types({}) }
qr/compression_types requires an ARRAY ref/, 'hashref compression_types throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types([]) }
qr/compression_types requires a non-empty ARRAY ref/, 'empty arrayref compression_types throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types([undef]) }
qr/passed empty value in compression_types/, 'undef compression_type throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types(['']) }
qr/passed empty value in compression_types/, 'empty compression_type throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types(['br', 'br']) }
qr/duplicate ext 'br'/, 'duplicate scalar ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'brc', encoding => 'br'}, 'br'])
}
qr/duplicate encoding 'br'/, 'duplicate scalar encoding throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->compression_types([{}]) }
qr/passed empty ext/, 'empty hash throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')->compression_types([{encoding => 'br'}])
}
qr/passed empty ext/, 'no hash ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')->compression_types([{ext => 'br'}])
}
qr/passed empty encoding/, 'no hash encoding throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => undef, encoding => 'br'}])
}
qr/passed empty ext/, 'undef hash ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => '', encoding => 'br'}])
}
qr/passed empty ext/, 'empty hash ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => undef}])
}
qr/passed empty encoding/, 'undef hash encoding throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => ''}])
}
qr/passed empty encoding/, 'empty hash encoding throws';

my $expected_hash_dump = Mojo::Util::dumper {key => 'value'};
throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => 'br', key => 'value'}])
}
qr/extra keys and values passed in hash besides 'ext' and 'encoding': \Q$expected_hash_dump\E/,
    'extra key/value throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => 'br', key => 'value', key2 => 'value2'}])
}
qr/extra keys and values passed in hash besides 'ext' and 'encoding': /,
    'multiple extra keys/values throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => 'gzip'}, {ext => 'br', encoding => 'br'}])
}
qr/duplicate ext 'br'/, 'duplicate hash ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'gz', encoding => 'gzip'}, {ext => 'br', encoding => 'gzip'}])
}
qr/duplicate encoding 'gzip'/, 'duplicate hash encoding throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types(['br', {ext => 'br', encoding => 'gzip'}])
}
qr/duplicate ext 'br'/, 'duplicate scalar then hash ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'br', encoding => 'gzip'}, 'br'])
}
qr/duplicate ext 'br'/, 'duplicate hash then scalar ext throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types(['br', {ext => 'gz', encoding => 'br'}])
}
qr/duplicate encoding 'br'/, 'duplicate scalar then hash encoding throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([{ext => 'gz', encoding => 'gzip'}, 'gzip'])
}
qr/duplicate encoding 'gzip'/, 'duplicate hash then scalar encoding throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types(['br', {ext => 'gz', encoding => 'gzip'}, []])
}
qr/passed illegal value to compression_types\. Each value of the ARRAY ref must be a scalar or a HASH ref with only the keys 'ext' and 'encoding' and their values, but reftype was 'ARRAY'/,
    'non scalar or hash (ARRAY) throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types(['br', sub { }, {ext => 'gz', encoding => 'gzip'}])
}
qr/passed illegal value to compression_types\. Each value of the ARRAY ref must be a scalar or a HASH ref with only the keys 'ext' and 'encoding' and their values, but reftype was 'CODE'/,
    'non scalar or hash (CODE) throws';

throws_ok {
    Mojolicious::Static->new->with_roles('+Compressed')
        ->compression_types([qr//, 'br', {ext => 'gz', encoding => 'gzip'}])
}
qr/passed illegal value to compression_types\. Each value of the ARRAY ref must be a scalar or a HASH ref with only the keys 'ext' and 'encoding' and their values, but reftype was 'REGEXP'/,
    'non scalar or hash (REGEXP) throws';

my $static = Mojolicious::Static->new;
lives_ok {
    $static->with_roles('+Compressed')
        ->compression_types(['abc', {ext => 'd', encoding => 'd-encode'}])
}
'legal compression_types succeed';

is_deeply $static->compression_types,
    [{ext => 'abc', encoding => 'abc'}, {ext => 'd', encoding => 'd-encode'}],
    'compression_types set';

# test that once we've successfully served a compressed asset, compression_types cannot be set

app->static->with_roles('+Compressed')
    ->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]);

lives_ok { app->static->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]) }
'can set compression_types before serving any compressed assets';

my $t = Test::Mojo->new;

# hello.txt has no compressed types
my $hello_etag          = etag('hello.txt');
my $hello_last_modified = last_modified('hello.txt');
$t->get_ok('/hello.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $hello_etag)
    ->header_is('Last-Modified' => $hello_last_modified)
    ->content_is("Hello Mojo from a static file!\n");

lives_ok { app->static->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]) }
'can set compression_types after serving non-compressed asset';

my ($goodbye_etag, $goodbye_etag_br) = etag('goodbye.txt', 'br');
my $goodbye_last_modified = last_modified('goodbye.txt');
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");

throws_ok { app->static->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]) }
qr/compression_types cannot be changed once serve_asset has served a compressed asset/,
    'cannot set compression_types after serving compressed asset';

$t->get_ok('/hello.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $hello_etag)
    ->header_is('Last-Modified' => $hello_last_modified)
    ->content_is("Hello Mojo from a static file!\n");

throws_ok { app->static->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]) }
qr/compression_types cannot be changed once serve_asset has served a compressed asset/,
    'set compression_types still throws after serving a non-compressed asset';

done_testing;
