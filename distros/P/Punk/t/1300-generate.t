#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Spec ();
use Cwd ();
use Punk::Generate;

# The scaffolder. Asserting the file list would only prove the generator
# copies files; what matters is that the generated tree is a working
# application, so each case builds one and drives it through its own to_app.

my $CWD  = Cwd::getcwd();
my $SPEC = "$FindBin::Bin/test/MyApp/openapi.json";

# Build and request against a generated application, one [ METHOD, PATH, %env ]
# per request. Done in a child so the
# generated class, its chdir and its config cannot leak into this process or
# into the next case - two generated apps in one interpreter would collide on
# package names.
sub drive {
    my ($dir, @requests) = @_;
    my $perl = $^X;
    my $inc  = join ' ', map { '-I' . _q($_) } grep { !ref } @INC;
    my $reqs = join ',', map { "[" . join(',', map { _q($_) } @$_) . "]" } @requests;
    # $0 is what FindBin reads, and app.psgi uses it to find lib/ and to
    # chdir to the application root - so set it exactly as a server loading
    # the file would, rather than chdir-ing first and proving less.
    my $code = <<"CHILD";
\$0 = '$dir/app.psgi';
my \$app = do \$0 or die(\$\@ || \$!);
for my \$r ($reqs) {
    my (\$method, \$path, \@extra) = (\$r->[0], \$r->[1], \@{\$r}[2..\$#\$r]);
    my \$res = \$app->({
        REQUEST_METHOD => \$method, PATH_INFO => \$path,
        QUERY_STRING => '', SERVER_NAME => 'x', SERVER_PORT => 80,
        HTTP_HOST => 'x', 'psgi.url_scheme' => 'http',
        \@extra,
    });
    my \$body = ref \$res->[2] eq 'ARRAY' ? join('', map { \$_ // '' } \@{\$res->[2]}) : '';
    \$body =~ s/\\n/\\\\n/g;
    print \$res->[0], "\\t", \$body, "\\n";
}
CHILD
    my $out = qx{$perl $inc -e @{[ _q($code) ]} 2>&1};
    return { error => $out } if $? != 0;
    return { rows => [ map { [ split /\t/, $_, 2 ] } split /\n/, $out ] };
}

sub _q { my $s = shift; $s =~ s/'/'\\''/g; return "'$s'" }

sub tempdir { return File::Temp::tempdir(CLEANUP => 1) }

# ---- a plain application -----------------------------------------------------

{
    my $root = tempdir();
    my $dir  = "$root/DemoApp";
    my $gen  = Punk::Generate->new(name => 'DemoApp', dir => $dir);
    my @files = $gen->run;

    is($gen->name, 'DemoApp', 'the generator reports its name');
    is($gen->dir,  $dir,      'and its directory');

    for my $want (qw(
        app.psgi config/punk.yml lib/DemoApp.pm
        lib/DemoApp/Controller/Web/Root.pm
        root/templates/layout.tmpl root/templates/welcome.tmpl
        root/static/style.css t/01-basic.t README.md .gitignore
    )) {
        ok(-f "$dir/$want", "wrote $want");
    }
    is_deeply([ sort @files ],
        [ sort qw(app.psgi config/punk.yml lib/DemoApp.pm
                  lib/DemoApp/Controller/Web/Root.pm t/01-basic.t README.md
                  .gitignore root/templates/layout.tmpl
                  root/templates/welcome.tmpl root/static/style.css) ],
        'run returns exactly what it wrote');

    ok(!-e "$dir/openapi.json", 'no spec without --api');
    unlike(_slurp("$dir/lib/DemoApp.pm"), qr/\bapi\b/,
        'and no api mount in the application class');

    # The name reaches every file that should carry it.
    like(_slurp("$dir/lib/DemoApp.pm"), qr/^package DemoApp;/m, 'package line');
    like(_slurp("$dir/app.psgi"), qr/DemoApp->to_app/, 'psgi builds the app');
    like(_slurp("$dir/README.md"), qr/^# DemoApp/m, 'readme is titled');

    # Nothing unrendered escaped: a leftover tag would mean a variable the
    # generator never passed.
    for my $f (@files) {
        next if $f =~ m{^root/templates/};   # these are templates by design
        next if $f eq 'config/punk.yml';     # deliberately shows one, escaped,
                                             # and the assertion below checks it
        unlike(_slurp("$dir/$f"), qr/\{%/, "no unrendered tag left in $f");
    }

    # The gitignored config layer is the one Punk::Config exempts from its
    # secret guardrail, so the generated tree should already list it.
    like(_slurp("$dir/.gitignore"), qr{^config/punk\.local\.yml$}m,
        'gitignore covers the local config layer');

    # A skeleton file that wants to *show* a Stencil tag has to escape it with
    # {%%}; forget that and the generator silently eats the example. The
    # config comment demonstrating csrf_field is the case that caught it.
    like(_slurp("$dir/config/punk.yml"), qr/\{% raw csrf %\}/,
        'an escaped tag survives generation into the generated file');

    # ---- it runs ----
    my $r = drive($dir, [ GET => '/' ], [ GET => '/static/style.css' ],
                        [ GET => '/nope' ]);
    ok(!$r->{error}, 'the generated application builds and serves')
        or diag $r->{error};
    SKIP: {
        skip 'the application did not build', 4 if $r->{error};
        is($r->{rows}[0][0], 200, 'GET / is 200');
        like($r->{rows}[0][1], qr/DemoApp/, '...and renders the welcome page');
        is($r->{rows}[1][0], 200, 'the stylesheet is served from root/static');
        is($r->{rows}[2][0], 404, 'an unknown path is 404');
    }
}

# ---- guardrails --------------------------------------------------------------

{
    my $root = tempdir();
    my $dir  = "$root/Twice";
    Punk::Generate->new(name => 'Twice', dir => $dir)->run;

    my $err = '';
    eval { Punk::Generate->new(name => 'Twice', dir => $dir)->run } or $err = $@;
    like($err, qr/is not empty/, 'it refuses to write into a non-empty tree');

    $err = '';
    eval { Punk::Generate->new(name => 'Twice', dir => $dir, force => 1)->run }
        or $err = $@;
    is($err, '', 'force writes into it anyway');

    # An empty directory that already exists is not an obstacle.
    my $empty = "$root/Empty";
    mkdir $empty;
    $err = '';
    eval { Punk::Generate->new(name => 'Empty', dir => $empty)->run } or $err = $@;
    is($err, '', 'an existing empty directory is fine');
}

{
    for my $bad ('9Bad', 'has space', 'Trailing::', '', undef) {
        my $err = '';
        eval { Punk::Generate->new(name => $bad, dir => tempdir() . '/x') }
            or $err = $@;
        like($err, qr/required|not a legal Perl package name/,
            'rejects the name ' . (defined $bad ? "'$bad'" : 'undef'));
    }
    my $err = '';
    eval { Punk::Generate->new(name => 'NoSpec', dir => tempdir() . '/x',
                               api => '/no/such/spec.json')->run } or $err = $@;
    like($err, qr/no such spec file/, 'rejects a missing spec');
}

{   # a nested name becomes a CPAN-style directory
    is(Punk::Generate->new(name => 'My::App')->dir, 'My-App',
        'My::App defaults to the My-App directory');
    my $root = tempdir();
    my $gen  = Punk::Generate->new(name => 'My::App', dir => "$root/My-App");
    $gen->run;
    ok(-f "$root/My-App/lib/My/App.pm", 'and the class nests under lib/My/');
    like(_slurp("$root/My-App/lib/My/App.pm"), qr/^package My::App;/m,
        'with the right package name');
}

# ---- with a spec -------------------------------------------------------------

SKIP: {
    skip 'the fixture spec is missing', 12 unless -f $SPEC;

    my $root = tempdir();
    my $dir  = "$root/ApiDemo";
    my @files = Punk::Generate->new(
        name => 'ApiDemo', dir => $dir, api => $SPEC)->run;

    ok(-f "$dir/openapi.json", 'the spec is copied into the application');

    my @ctrl = grep { m{^lib/ApiDemo/Controller/API/} } @files;
    ok(scalar @ctrl, 'at least one API controller was generated')
        or diag explain \@files;

    # The fixture has no tags, so grouping falls back to the path segment.
    is_deeply([ sort @ctrl ], [ 'lib/ApiDemo/Controller/API/Books.pm' ],
        'untagged operations group by first path segment');

    my $api = _slurp("$dir/lib/ApiDemo/Controller/API/Books.pm");
    for my $op (qw(allBooks getBook addBook)) {
        like($api, qr/^sub \Q$op\E \{/m, "$op became a sub");
    }
    like($api, qr/501/, 'the stubs answer 501');
    like(_slurp("$dir/lib/ApiDemo.pm"), qr/under\('\/api'\)->api\('openapi\.json'\)/,
        'the application class mounts the spec');

    my $r = drive($dir, [ GET => '/' ], [ GET => '/api/books' ],
                        [ GET => '/api/books/1' ]);
    ok(!$r->{error}, 'the generated API application builds and serves')
        or diag $r->{error};
    SKIP: {
        skip 'the application did not build', 3 if $r->{error};
        is($r->{rows}[0][0], 200, 'the web route still works alongside the api');
        is($r->{rows}[1][0], 501,
            'a spec operation routes to its generated stub');
        like($r->{rows}[2][1], qr/getBook/,
            'a templated path reaches the operation named for it');
    }
}

# ---- grouping by tag ---------------------------------------------------------
# The fixture is untagged; a tagged document has to group the other way, and
# a tag that is not a legal identifier has to be made into one.

{
    my $root = tempdir();
    my $spec = "$root/tagged.json";
    _spew($spec, <<'JSON');
{
  "openapi": "3.1.0",
  "info": { "title": "Tagged", "version": "1" },
  "paths": {
    "/widgets": {
      "get": { "operationId": "listWidgets", "tags": ["Stock & Parts"],
               "summary": "Every widget",
               "responses": { "200": { "description": "ok" } } }
    },
    "/gizmos": {
      "get": { "operationId": "listGizmos", "tags": ["Stock & Parts"],
               "responses": { "200": { "description": "ok" } } }
    },
    "/health": {
      "get": { "operationId": "health",
               "responses": { "200": { "description": "ok" } } }
    }
  }
}
JSON
    my $dir = "$root/Tagged";
    my @files = Punk::Generate->new(name => 'Tagged', dir => $dir,
                                    api => $spec)->run;
    my @ctrl = sort grep { m{^lib/Tagged/Controller/API/} } @files;
    is_deeply(\@ctrl,
        [ 'lib/Tagged/Controller/API/Default.pm',
          'lib/Tagged/Controller/API/StockParts.pm' ],
        'tags group operations, and an untagged one falls to Default');

    my $sp = _slurp("$dir/lib/Tagged/Controller/API/StockParts.pm");
    like($sp, qr/^sub listWidgets \{/m, 'both tagged operations are together');
    like($sp, qr/^sub listGizmos \{/m,  '...including the second');
    like($sp, qr/Every widget/, 'the summary rides along into the stub');
}

# ---- determinism -------------------------------------------------------------
# operations comes back in hash order, which perl randomises per process. If
# the generator did not sort, regenerating the same spec would shuffle subs
# between and within files and every diff would be noise.

SKIP: {
    skip 'the fixture spec is missing', 1 unless -f $SPEC;
    my @runs;
    for my $n (1, 2) {
        my $dir = tempdir() . "/Same";
        my @files = Punk::Generate->new(name => 'Same', dir => $dir,
                                        api => $SPEC)->run;
        push @runs, join "\0", map { "$_\n" . _slurp("$dir/$_") } sort @files;
    }
    is($runs[0], $runs[1],
        'the same spec generates byte-identical files every time');
}

# ---- security schemes --------------------------------------------------------
# A spec that requires a securityScheme needs a checker registered in the
# mount, or Punk croaks at boot naming the scheme. The scaffolder owes one
# stub per required scheme, and the stubs have to refuse - a generated checker
# that returned true would silently open every operation the spec protects.

{
    my $root = tempdir();
    my $spec = "$root/secured.json";
    _spew($spec, <<'JSON');
{
  "openapi": "3.1.0",
  "info": { "title": "Secured", "version": "1" },
  "components": { "securitySchemes": {
    "adminToken": { "type": "http", "scheme": "bearer" },
    "apiKey":     { "type": "apiKey", "in": "header", "name": "X-Key" },
    "neverUsed":  { "type": "http", "scheme": "basic" }
  } },
  "paths": {
    "/rooms": {
      "get": { "operationId": "listRooms",
               "responses": { "200": { "description": "ok" } } },
      "delete": { "operationId": "clearRooms", "security": [ { "adminToken": [] } ],
                  "responses": { "204": { "description": "gone" } } }
    },
    "/keyed": {
      "get": { "operationId": "keyed", "security": [ { "apiKey": [] } ],
               "responses": { "200": { "description": "ok" } } }
    }
  }
}
JSON
    my $dir = "$root/Secured";
    my @files = Punk::Generate->new(name => 'Secured', dir => $dir,
                                    api => $spec)->run;

    ok(-f "$dir/lib/Secured/Controller/API/Auth.pm",
        'a required scheme gets a checker class');

    my $auth = _slurp("$dir/lib/Secured/Controller/API/Auth.pm");
    like($auth, qr/^sub adminToken \{/m, 'a checker per required scheme');
    like($auth, qr/^sub apiKey \{/m,     '...and the second one');
    unlike($auth, qr/\bneverUsed\b/,
        'a scheme the spec never requires gets no checker');
    like($auth, qr/without the "Bearer " prefix/,
        'the stub says what the credential will be');

    my $class = _slurp("$dir/lib/Secured.pm");
    like($class, qr/security\s*=>/, 'the mount carries a security option');
    like($class, qr/'adminToken'\s*=>\s*'API::Auth\#adminToken'/,
        'mapping the spec name to the generated checker');

    # It boots - the failure this whole block exists for - and refuses.
    my $r = drive($dir, [ GET => '/api/rooms' ], [ DELETE => '/api/rooms' ],
        [ GET => '/api/keyed' ],
        [ DELETE => '/api/rooms', HTTP_AUTHORIZATION => 'Bearer t0ken' ]);
    ok(!$r->{error}, 'an application generated from a secured spec boots')
        or diag $r->{error};
    SKIP: {
        skip 'the application did not build', 4 if $r->{error};
        is($r->{rows}[0][0], 501, 'an unsecured operation reaches its stub');
        is($r->{rows}[1][0], 401, 'a secured one is refused by the stub');
        is($r->{rows}[2][0], 401, '...and so is the apiKey one');
        is($r->{rows}[3][0], 401,
            '...including a request that does present a credential');
    }

    # The wiring is live, not merely failing closed: implement the checker and
    # the same request reaches its operation stub.
    my $impl = $auth;
    $impl =~ s/^sub adminToken \{.*?^\}/sub adminToken { return { who => 'admin' } }/ms;
    _spew("$dir/lib/Secured/Controller/API/Auth.pm", $impl);
    my $r2 = drive($dir,
        [ DELETE => '/api/rooms', HTTP_AUTHORIZATION => 'Bearer t0ken' ]);
    ok(!$r2->{error}, 'the application still builds with a real checker')
        or diag $r2->{error};
    SKIP: {
        skip 'the application did not build', 1 if $r2->{error};
        is($r2->{rows}[0][0], 501,
            'an authorised request reaches the operation stub');
    }
}

{   # a tag called Auth already owns that file, so the checkers move aside
    my $root = tempdir();
    my $spec = "$root/clash.json";
    _spew($spec, <<'JSON');
{
  "openapi": "3.1.0",
  "info": { "title": "Clash", "version": "1" },
  "components": { "securitySchemes": {
    "tok": { "type": "http", "scheme": "bearer" } } },
  "paths": {
    "/login": {
      "post": { "operationId": "login", "tags": ["Auth"],
                "responses": { "200": { "description": "ok" } } }
    },
    "/me": {
      "get": { "operationId": "me", "tags": ["Auth"], "security": [ { "tok": [] } ],
               "responses": { "200": { "description": "ok" } } }
    }
  }
}
JSON
    my $dir = "$root/Clash";
    Punk::Generate->new(name => 'Clash', dir => $dir, api => $spec)->run;

    like(_slurp("$dir/lib/Clash/Controller/API/Auth.pm"), qr/^sub login \{/m,
        'the Auth tag keeps its operations');
    ok(-f "$dir/lib/Clash/Controller/API/Security.pm",
        'and the checkers take the next free name');
    like(_slurp("$dir/lib/Clash.pm"), qr/'API::Security\#tok'/,
        'which is what the mount points at');
}

sub _slurp {
    my ($f) = @_;
    open my $fh, '<', $f or die "cannot read $f: $!";
    local $/;
    return <$fh>;
}

sub _spew {
    my ($f, $c) = @_;
    open my $fh, '>', $f or die "cannot write $f: $!";
    print $fh $c;
    close $fh;
}

END { chdir $CWD if $CWD }

done_testing();
