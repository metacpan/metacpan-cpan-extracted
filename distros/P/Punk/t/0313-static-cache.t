#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use File::Spec ();
use Test::More;
use Punk ();

# Freshness on static mounts: Cache-Control from the mount's options, and
# content-addressed URLs - /app.<digest>.css served from app.css, with a
# year and `immutable` only once the digest has been checked against the
# file. A validator makes a stale copy cheap to detect; it does not make it
# unnecessary to ask, which is what these headers are for.

my $dir  = File::Temp->newdir;
my $root = "$dir";

sub w {
    my ($name, $bytes, $mtime) = @_;
    my $p = File::Spec->catfile($root, $name);
    open my $fh, '>', $p or die "$p: $!";
    binmode $fh;
    print $fh $bytes;
    close $fh;
    utime $mtime, $mtime, $p if $mtime;
    return $p;
}

my $NOW = time;
w('app.css',   'body { color: red }', $NOW - 100);
w('app.js',    'console.log(1)',      $NOW - 100);
w('README',    'no extension here',   $NOW - 100);
w('gz.css',    'body { color: blue }' x 50, $NOW - 100);
w('gz.css.gz', 'PRETEND-GZIP',              $NOW);

sub req {
    my ($app, $path, %extra) = @_;
    open my $in, '<', \'';
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        'psgi.input'   => $in,
        %extra,
    });
    my %h = @{ $res->[1] };
    my $body = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] })
             : do { my $g = $res->[2]; local $/; my $b = <$g>; close $g; $b // '' };
    return ($res->[0], \%h, $body);
}

# ---- no options: exactly what it did before --------------------------------

{
    my $app = do {
        package Plain;
        use Punk;
        static '/s' => $root;
        get '/url' => sub { $_[0]->text($_[0]->asset('/s/app.css')) };
        __PACKAGE__->to_app;
    };

    my ($st, $h) = req($app, '/s/app.css');
    is $st, 200, 'a plain mount still serves';
    ok !exists $h->{'Cache-Control'},
       'a mount that was told nothing sends no Cache-Control';
    ok $h->{ETag} && $h->{'Last-Modified'}, '...and still validates';

    # fingerprinting is opt-in: a mount that did not ask for it behaves
    # exactly as it did before, down to what a fingerprint-shaped path means
    my (undef, undef, $url) = req($app, '/url');
    is $url, '/s/app.css', '$c->asset is inert until the mount opts in';
    is +(req($app, '/s/app.0123456789abcdef.css'))[0], 404,
       '...and a fingerprint-shaped path is still just a missing file';
}

# ---- max_age and cache_control ---------------------------------------------

{
    my $app = do {
        package Aged;
        use Punk;
        static '/s' => $root, max_age => 3600;
        __PACKAGE__->to_app;
    };

    my ($st, $h) = req($app, '/s/app.css');
    is $h->{'Cache-Control'}, 'public, max-age=3600', 'max_age becomes one';

    # The 304 must carry it too. Without it the stored response keeps the
    # lifetime that has just run out, so the next load revalidates again and
    # the header bought exactly one hit.
    my ($st2, $h2) = req($app, '/s/app.css',
                         HTTP_IF_NONE_MATCH => $h->{ETag});
    is $st2, 304, 'a matching validator is still a 304';
    is $h2->{'Cache-Control'}, 'public, max-age=3600',
       '...and the 304 renews the freshness lifetime';
}

{
    my $app = do {
        package Verbatim;
        use Punk;
        static '/s' => $root,
            max_age => 3600, cache_control => 'private, no-store';
        __PACKAGE__->to_app;
    };
    my (undef, $h) = req($app, '/s/app.css');
    is $h->{'Cache-Control'}, 'private, no-store',
       'cache_control is verbatim and beats max_age';
}

# ---- content-addressed URLs -------------------------------------------------

my $FP = do {
    my $app = do {
        package Named;
        use Punk;
        static '/s' => $root, fingerprint => 1;
        get '/url'  => sub { $_[0]->text($_[0]->asset($_[0]->param('u'))) };
        __PACKAGE__->to_app;
    };
    sub asset_of {
        my $u = shift;
        my (undef, undef, $body) = req($app, '/url', QUERY_STRING => "u=$u");
        return $body;
    }
    $app;
};

{
    my $url = asset_of('/s/app.css');
    like $url, qr{^/s/app\.[0-9a-f]{16}\.css$}, 'the digest goes before the extension';

    my ($st, $h, $b) = req($FP, $url);
    is $st, 200, 'the fingerprinted URL serves the file';
    is $b, 'body { color: red }', '...with the right bytes';
    is $h->{'Content-Type'}, 'text/css; charset=utf-8',
       '...and the type of the file it names, not of the digest';
    is $h->{'Cache-Control'}, 'public, max-age=31536000, immutable',
       '...and a year, because that URL cannot come to mean anything else';

    my ($st3, $h3) = req($FP, $url, HTTP_IF_NONE_MATCH => $h->{ETag});
    is $st3, 304, 'it still answers a conditional request';
    is $h3->{'Cache-Control'}, 'public, max-age=31536000, immutable',
       '...and that 304 carries the lifetime too';
}

{
    # two files, two digests - the URL is keyed on the bytes, not the mount
    isnt asset_of('/s/app.css'), asset_of('/s/app.js'),
       'different files get different digests';
}

{
    # A URL from an older deploy: the digest does not match what the file now
    # holds. The current bytes are still the right answer, but `immutable`
    # would be a lie about a URL whose meaning has already changed once.
    my ($st, $h, $b) = req($FP, '/s/app.0123456789abcdef.css');
    is $st, 200, 'a stale digest still serves the current file';
    is $b, 'body { color: red }', '...with the current bytes';
    ok !exists $h->{'Cache-Control'},
       '...and no immutable claim about a URL that has already moved once';
}

{
    my ($st) = req($FP, '/s/nope.0123456789abcdef.css');
    is $st, 404, 'a fingerprinted URL for a missing file is still a 404';
}

{
    # A file genuinely checked in under a fingerprinted name serves as
    # itself: the literal path is tried first.
    w('build.0123456789abcdef.css', 'REAL FILE', $NOW - 100);
    my ($st, undef, $b) = req($FP, '/s/build.0123456789abcdef.css');
    is $st, 200, 'a real file named like a fingerprint serves';
    is $b, 'REAL FILE', '...as itself, not as build.css';
}

{
    is asset_of('/s/README'), '/s/README',
       'a path with no extension has nowhere to put a digest, and is left alone';
    is asset_of('/s/missing.css'), '/s/missing.css',
       'an unreadable file comes back as the URL that went in';
    is asset_of('/elsewhere/app.css'), '/elsewhere/app.css',
       'a URL under no static mount is left alone';
}

# ---- fingerprint => 0 -------------------------------------------------------

{
    my $app = do {
        package Off;
        use Punk;
        static '/s' => $root, fingerprint => 0, max_age => 60;
        get '/url' => sub { $_[0]->text($_[0]->asset('/s/app.css')) };
        __PACKAGE__->to_app;
    };

    my (undef, undef, $url) = req($app, '/url');
    is $url, '/s/app.css', 'fingerprint => 0 hands back the plain URL';

    my ($st) = req($app, '/s/app.0123456789abcdef.css');
    is $st, 404, '...and a fingerprinted path is not resolved at all';

    my (undef, $h) = req($app, '/s/app.css');
    is $h->{'Cache-Control'}, 'public, max-age=60',
       '...while max_age still applies';
}

# ---- precompressed siblings still work under a fingerprinted URL ------------

{
    my $url = asset_of('/s/gz.css');
    my ($st, $h, $b) = req($FP, $url, HTTP_ACCEPT_ENCODING => 'gzip');
    is $st, 200, 'a fingerprinted URL serves its gzip sibling';
    is $h->{'Content-Encoding'}, 'gzip', '...tagged gzip';
    is $b, 'PRETEND-GZIP', '...with the sibling bytes';
    is $h->{'Cache-Control'}, 'public, max-age=31536000, immutable',
       '...and the digest of the identity file still names the URL';
    is $h->{Vary}, 'Accept-Encoding', '...Vary intact';
}

# ---- development re-checks, production believes the cache -------------------

{
    my $edit = File::Spec->catfile($root, 'edit.css');
    w('edit.css', 'body { color: red }', $NOW - 100);

    my $prod = Punk::Static->app($root, { dev => 0, fingerprint => 1 });
    my $dev  = Punk::Static->app($root, { dev => 1, fingerprint => 1 });

    my $p1 = Punk::Static::_asset($prod, '/edit.css');
    my $d1 = Punk::Static::_asset($dev,  '/edit.css');
    is $p1, $d1, 'both see the same file the same way';

    w('edit.css', 'body { color: green }', $NOW - 50);

    is Punk::Static::_asset($prod, '/edit.css'), $p1,
       'production believes its cache: files do not change under a live process';
    isnt Punk::Static::_asset($dev, '/edit.css'), $d1,
       'development re-checks, so editing a file shows up on reload';
}

# ---- the template filter ----------------------------------------------------

SKIP: {
    eval { require Template::Stencil; 1 }
        or skip 'Template::Stencil not available', 3;

    my $tdir = File::Temp->newdir;
    open my $fh, '>', "$tdir/page.tmpl" or die $!;
    print $fh '<link href="{% css | asset %}"><b>{% plain | asset %}</b>';
    close $fh;

    my $app = do {
        package Templated;
        use Punk;
        views Stencil => { template_dir => "$tdir" };
        static '/s' => $root, fingerprint => 1;
        get '/page' => sub {
            $_[0]->render('page', { css => '/s/app.css', plain => '/s/README' });
        };
        __PACKAGE__->to_app;
    };

    my (undef, undef, $body) = req($app, '/page');
    like $body, qr{href="/s/app\.[0-9a-f]{16}\.css"},
       'a template can name an asset with the asset filter';
    like $body, qr{<b>/s/README</b>},
       '...and a URL it cannot fingerprint passes straight through';

    # the filter must not displace one the application registered itself
    my $mine = do {
        package OwnFilter;
        use Punk;
        views Stencil => { template_dir => "$tdir",
                           filters => { asset => sub { "MINE:$_[0]" } } };
        static '/s' => $root, fingerprint => 1;
        get '/page' => sub {
            $_[0]->render('page', { css => '/s/app.css', plain => '/s/README' });
        };
        __PACKAGE__->to_app;
    };
    my (undef, undef, $own) = req($mine, '/page');
    like $own, qr{href="MINE:/s/app\.css"},
       'an application filter of the same name wins';
}

# ---- the mount's own errors -------------------------------------------------

{
    eval { Punk::Static->app($root, nonsense => 1) };
    like $@, qr/unknown option 'nonsense'/, 'a mistyped option fails at boot';
}

done_testing;
