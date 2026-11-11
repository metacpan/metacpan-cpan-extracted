#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The option keywords in their three spellings: a hashref, key => value
# pairs, and a false scalar that turns the policy back off, plus the
# refusals each one makes at declaration time rather than at request time.

{
    package KwApp;
    use Punk;
    get '/' => sub { $_[0]->text('ok') };
    package main;
}
my $app = KwApp->punk_app;

sub refuses {
    my ($re, $name, $code) = @_;
    my $err = '';
    eval { $code->(); 1 } or $err = $@;
    like($err, $re, $name);
}
sub accepts {
    my ($name, $code) = @_;
    my $err = '';
    eval { $code->(); 1 } or $err = $@;
    is($err, '', $name);
}

# ---- cors --------------------------------------------------------------------
accepts('cors as a hashref', sub { $app->cors({ origins => [ 'https://a.example' ] }) });
accepts('cors as pairs', sub { $app->cors(origins => [ 'https://a.example' ], credentials => 1) });
accepts('cors 0 turns it off', sub { $app->cors(0) });
refuses(qr/cors credentials => 1` needs explicit origins/, 'credentials without origins is refused',
    sub { $app->cors(credentials => 1) });
refuses(qr/needs explicit origins/, 'credentials with a * origin is refused',
    sub { $app->cors(credentials => 1, origins => '*') });
accepts('credentials with one named origin', sub { $app->cors(credentials => 1, origins => 'https://a.example') });

# ---- headers -----------------------------------------------------------------
accepts('headers as a hashref', sub { $app->headers({ 'X-Frame-Options' => 'DENY' }) });
accepts('headers as pairs, undef drops a default', sub { $app->headers('X-Frame-Options' => undef) });
accepts('headers 0 turns it off', sub { $app->headers(0) });
refuses(qr/headers needs header names as keys/, 'an empty header name is refused',
    sub { $app->headers('' => 'x') });
refuses(qr/headers value for 'X-A' must be a string/, 'a reference as a header value is refused',
    sub { $app->headers('X-A' => []) });

# ---- proxy -------------------------------------------------------------------
accepts('proxy 0 with nothing declared', sub { $app->proxy(0) });
accepts('proxy as a hashref', sub { $app->proxy({ trust => [ '10.0.0.0/8' ] }) });
refuses(qr/`proxy` is already declared/, 'a second proxy declaration is refused',
    sub { $app->proxy(trust => [ '10.0.0.1' ]) });
accepts('proxy 0 clears it', sub { $app->proxy(0) });
accepts('and the next declaration is the first again', sub { $app->proxy(trust => [ '10.0.0.1' ]) });

# ---- auth --------------------------------------------------------------------
accepts('auth as a hashref', sub { $app->auth({ model => 'User', fields => { email => 'mail' } }) });
accepts('auth 0 turns it off', sub { $app->auth(0) });
refuses(qr/auth fields must be a hashref/, 'auth fields that are not a hashref are refused',
    sub { $app->auth(fields => 'email') });
refuses(qr/unknown auth field 'bogus'/, 'an unknown auth field is refused',
    sub { $app->auth(fields => { bogus => 'x' }) });
refuses(qr/auth iterations must be positive/, 'zero iterations are refused',
    sub { $app->auth(iterations => 0) });
refuses(qr/auth iterations must be between/, 'too few iterations are refused',
    sub { $app->auth(iterations => 1) });
refuses(qr/unknown auth option 'bogus'/, 'an unknown auth option is refused',
    sub { $app->auth(bogus => 1) });

# ---- auth_guard --------------------------------------------------------------
accepts('auth_guard as a hashref', sub { $app->auth_guard({ role => 'admin' }) });
is(ref $app->auth_guard(on_denied => '404'), 'CODE', 'auth_guard returns a guard');
is(ref $app->auth_guard(on_denied => sub { }), 'CODE', 'with a coderef for on_denied');
refuses(qr/unknown auth_guard option 'bogus'/, 'an unknown guard option is refused',
    sub { $app->auth_guard(bogus => 1) });
refuses(qr/auth_guard on_denied takes '403', '404' or a coderef/, 'a stray on_denied is refused',
    sub { $app->auth_guard(on_denied => '500') });
refuses(qr/on_denied takes/, 'a reference that is not code is refused',
    sub { $app->auth_guard(on_denied => []) });

# ---- csrf --------------------------------------------------------------------
accepts('csrf as a hashref', sub { $app->csrf({ cookie => 'tok' }) });
accepts('csrf 0 turns it off', sub { $app->csrf(0) });
refuses(qr/csrf `cookie` may not contain/, 'a cookie name with a semicolon is refused',
    sub { $app->csrf(cookie => 'a;b') });
refuses(qr/csrf `header` name is longer than 120 bytes/, 'an overlong header name is refused',
    sub { $app->csrf(header => 'X' x 121) });

# ---- ua ----------------------------------------------------------------------
accepts('ua as a hashref', sub { $app->ua({ timeout => 1 }) });
accepts('ua with a name and a hashref', sub { $app->ua(partner => { timeout => 2 }) });
accepts('ua as pairs', sub { $app->ua(timeout => 3) });
refuses(qr/ua takes a hashref, a list of pairs, or a name and a hashref/, 'an odd list is refused',
    sub { $app->ua('timeout') });

# ---- routes, mounts, static, markdown ------------------------------------------
refuses(qr/route options must be a hashref/, 'route options that are not a hashref are refused',
    sub { eval q{ package KwRoute; use Punk; get '/x' => sub { }, 'nope'; 1 } or die $@ });
refuses(qr/static takes a prefix, a directory and an even-sized option list/, 'an odd static option list is refused',
    sub { $app->static('/s', 't/test', 'odd') });
refuses(qr/markdown takes a prefix, a directory and an even-sized option list/, 'an odd markdown option list is refused',
    sub { $app->markdown('/d', 't/test/docs', 'odd') });
refuses(qr/mount needs a PSGI coderef/, 'options in the mount slot leave no app to mount', sub { $app->mount('/m', { lazy => 1 }) });

# ---- host and favicon ---------------------------------------------------------
refuses(qr/host takes key => value options/, 'an odd host option list is refused',
    sub { $app->host('https://a.example', 'odd') });
my $ico = 't/test/docs/guide/diagram.png';
refuses(qr/favicon needs a file path/, 'an empty favicon path is refused', sub { $app->favicon('') });
refuses(qr/favicon takes key => value options/, 'an odd favicon option list is refused',
    sub { $app->favicon($ico, 'odd') });
refuses(qr/favicon max_age needs a non-negative number of seconds/, 'a negative max_age is refused',
    sub { $app->favicon($ico, max_age => -1) });
refuses(qr/favicon does not understand 'bogus'/, 'an unknown favicon option is refused',
    sub { $app->favicon($ico, bogus => 1) });
accepts('favicon declared again with a max_age', sub { $app->favicon($ico, max_age => 60) });

# ---- url_for on the application -------------------------------------------------
{
    package UrlApp;
    use Punk;
    host 'https://url.example';
    get '/books/:id' => sub { $_[0]->text('b') }, { name => 'book' };
    package main;
}
my $uapp = UrlApp->punk_app;
UrlApp->to_app;
refuses(qr/url_for takes a route name then key => value pairs/, 'an odd url_for list is refused',
    sub { $uapp->url_for('book', 'odd') });
refuses(qr/url_for needs a route name/, 'an empty route name is refused', sub { $uapp->url_for('') });
refuses(qr/`query` takes a hashref/, 'a query that is not a hashref is refused',
    sub { $uapp->url_for('book', id => 1, query => 'x') });
refuses(qr/no route is named 'nope'/, 'an unknown route name is refused', sub { $uapp->url_for('nope') });
is($uapp->url_for('book', id => 7, absolute => 1, query => { page => 2 }), 'https://url.example/books/7?page=2',
    'an absolute URL with a query from the application itself');
is($uapp->url_for('book', id => 7, absolute => 0), '/books/7', 'absolute => 0 is relative');

# ---- config -------------------------------------------------------------------
ok(!defined $app->config, 'config reads back undef while nothing is loaded');
SKIP: {
    skip 'YAML::XS is not installed', 2 unless eval { require YAML::XS; 1 };
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/punk.yml" or die "$dir/punk.yml: $!";
    print $fh "host: https://cfg.example\n";
    close $fh;
    accepts('config as file => path pairs', sub { $app->config(file => "$dir/punk.yml", env => 'none') });
    is($app->host, 'https://cfg.example', 'and the file applied its blocks');
}

{
    package BasePlug;
    use parent 'Punk::Plugin';
    package PlugBaseApp;
    use Punk;
    plugin '+BasePlug';
    get '/' => sub { $_[0]->text('ok') };
    package main;
    ok(PlugBaseApp->to_app, 'a plugin that leaves register to Punk::Plugin registers nothing and compiles');
}

done_testing;
