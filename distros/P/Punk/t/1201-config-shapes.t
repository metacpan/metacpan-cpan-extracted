#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Every shape a punk.yml block can take, fed straight to _apply_config
# through an object whose resolved() hands back the mapping, so each arm of
# the block parser runs without a file: the database block flat, named and
# wrong, models as a mapping, a word, a name and a list, host and favicon as
# a mapping, bare and wrong, plugins, static, ua with a named agent, csrf and
# views.

{
    package FakeCfg;
    sub new      { my ($class, $r) = @_; bless { r => $r }, $class }
    sub resolved { $_[0]{r} }
}

sub apply {
    my ($class, $r) = @_;
    my $err = '';
    eval { $class->punk_app->_apply_config(FakeCfg->new($r)); 1 } or $err = $@;
    return $err;
}

{
    package ShapeApp;
    use Punk;
    get '/' => sub { $_[0]->text('ok') };
    package main;
}

is(apply('ShapeApp', { database => 'dbi:SQLite:dbname=:memory:' }) =~ /the config database block must be a mapping/ ? 1 : 0, 1,
    'a database block that is not a mapping is refused');
is(apply('ShapeApp', { database => { dsn => 'dbi:SQLite:dbname=:memory:' } }), '',
    'the flat database block names the default connection');
is(apply('ShapeApp', { database => { default => { dsn => 'dbi:SQLite:dbname=:memory:' },
                                     analytics => { dsn => 'dbi:SQLite:dbname=:memory:' } } }), '',
    'a mapping of named blocks registers the default and the named one');
is(apply('ShapeApp', { database => { default => undef, other => { dsn => 'dbi:SQLite:dbname=:memory:' } } }), '',
    'a default entry without options still counts as the default');

is(apply('ShapeApp', { models => 'auto' }), '', 'models: auto');
is(apply('ShapeApp', { models => 'NONE' }), '', 'models: none, in any case');
is(apply('ShapeApp', { models => { auto => 0 } }), '', 'models as a mapping with auto');
is(apply('ShapeApp', { models => { only => [ 'Nope' ] } }), '', 'models as a mapping with only names classes to resolve at boot');
is(apply('ShapeApp', { models => { auto => 1, only => [] } }), '', 'an empty only list is no list');
is(apply('ShapeApp', { models => 'Nope' }), '', 'models as one bare name');
is(apply('ShapeApp', { models => [ 'Nope', 'Other' ] }), '', 'models as a list of names');

is(apply('ShapeApp', { host => 'https://example.com' }), '', 'host as a bare origin');
is(ShapeApp->punk_app->host, 'https://example.com', 'and it is stored');
is(apply('ShapeApp', { host => { origin => 'https://example.org', allow => 'shop.example' } }), '',
    'host as a mapping with one bare allowed name');
is(apply('ShapeApp', { host => { origin => 'https://example.org', allow => [ 'a.example', 'b.example' ] } }), '',
    'host as a mapping with a list of allowed names');
is(apply('ShapeApp', { host => { origin => 'https://example.org' } }), '', 'host as a mapping with the origin alone');
like(apply('ShapeApp', { host => { allow => [ 'a.example' ] } }), qr/the config host block needs an origin/,
    'a host mapping without an origin is refused');
like(apply('ShapeApp', { host => { origin => [ 'x' ] } }), qr/the config host block needs an origin/,
    'an origin that is a reference is refused');
like(apply('ShapeApp', { host => [ 'https://example.com' ] }), qr/the config host block needs an origin/,
    'a host block that is a list is refused');

my $ico = 't/test/docs/guide/diagram.png';
SKIP: {
    skip 'no favicon fixture', 3 unless -f $ico;
    is(apply('ShapeApp', { favicon => $ico }), '', 'favicon as a bare path');
    is(apply('ShapeApp', { favicon => { path => $ico, max_age => 60 } }), '', 'favicon as a mapping with max_age');
    is(apply('ShapeApp', { favicon => { path => $ico } }), '', 'favicon as a mapping with the path alone');
}
like(apply('ShapeApp', { favicon => { max_age => 60 } }), qr/the config favicon block needs a path/,
    'a favicon mapping without a path is refused');
like(apply('ShapeApp', { favicon => [ $ico ] }), qr/the config favicon block needs a path/,
    'a favicon block that is a list is refused');

like(apply('ShapeApp', { static => '/static' }), qr/the config static block must be a mapping/,
    'a static block that is not a mapping is refused');
is(apply('ShapeApp', { static => { '/fixtures' => 't/test' } }), '', 'static as prefix => directory');

is(apply('ShapeApp', { plugins => { RequestId => {} } }), '', 'plugins as name => options');

is(apply('ShapeApp', { ua => { timeout => 10, partner => { timeout => 2 } } }), '',
    'ua with options for the default agent and a named one');
is(apply('ShapeApp', { ua => { partner => { timeout => 2 } } }), '', 'ua with a named agent alone');

is(apply('ShapeApp', { csrf => {} }), '', 'csrf as a mapping turns it on');
is(apply('ShapeApp', { csrf => { cookie => 'tok', field => 'f' } }), '', 'csrf as a mapping with options');
is(apply('ShapeApp', { csrf => 1 }), '', 'csrf: true is the bare keyword');
is(apply('ShapeApp', { cors => { origins => [ 'https://a.example' ] } }), '', 'cors as a mapping');
is(apply('ShapeApp', { cors => 1 }), '', 'cors: true is the bare keyword');
is(apply('ShapeApp', { headers => { 'X-Frame-Options' => 'DENY' } }), '', 'headers as a mapping');
is(apply('ShapeApp', { headers => 1 }), '', 'headers: true is the default set');
is(apply('ShapeApp', { auth => { session_key => 'uid' } }), '', 'auth as a mapping');
is(apply('ShapeApp', { logging => { level => 'warn' } }), '', 'logging as a mapping');

is(apply('ShapeApp', { views => { Stencil => { template_dir => 't/test' } } }), '', 'views as engine => options');

is(apply('ShapeApp', {}), '', 'an empty mapping applies nothing');

{
    package NoCfg;
    sub new { bless {}, shift }
    sub resolved { undef }
}
is(eval { ShapeApp->punk_app->_apply_config(NoCfg->new); 1 } ? '' : $@, '', 'a config with nothing resolved applies nothing');

is(apply('ShapeApp', { plugins => [ 'ConditionalGet', [ 'Health', {} ], { Metrics => {} } ] }), '',
    'plugins as a list of names, pairs and one-key mappings');
like(apply('ShapeApp', { plugins => 'RequestId' }), qr/the config plugins block must be a mapping or a list/,
    'plugins as a bare word is refused');
is(apply('ShapeApp', { models => { only => { Nope => 1 } } }), '', 'only as a mapping names its keys');
like(apply('ShapeApp', { models => { only => \'Nope' } }), qr/the config models\.only block must be a list/,
    'only as something else is refused');

done_testing;
