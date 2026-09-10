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
use Punk::Command;

# The punk subcommands. Each is run against a real generated application in a
# child process - they load an application class, chdir, and read %ENV, none of
# which should leak into this interpreter or into the next case.

my $CWD  = Cwd::getcwd();
my $BIN  = File::Spec->catfile($FindBin::Bin, File::Spec->updir, 'bin', 'punk');
my $SPEC = "$FindBin::Bin/test/MyApp/openapi.json";

plan skip_all => 'bin/punk is missing' unless -f $BIN;

# Run `punk <args>` inside $dir; returns (exit, output).
sub punk {
    my ($dir, @args) = @_;
    my $inc = join ' ', map { '-I' . _q($_) } grep { !ref } @INC;
    my $cmd = sprintf 'cd %s && %s %s %s %s 2>&1',
        _q($dir), _q($^X), $inc, _q($BIN), join(' ', map { _q($_) } @args);
    my $out = qx{$cmd};
    return ($? >> 8, $out // '');
}

sub _q { my $s = shift; $s =~ s/'/'\\''/g; return "'$s'" }
sub tempdir { File::Temp::tempdir(CLEANUP => 1) }

# Run a snippet in a child; returns (exit, output). @INC goes over absolute,
# because a snippet that loads an application ends up wherever app.psgi
# chdir-ed to, and a relative -I stops resolving there - which is how a blib
# quietly loses to an installed copy.
sub run_perl {
    my ($code, @args) = @_;
    my $inc = join ' ',
        map { '-I' . _q(Cwd::abs_path($_) // $_) } grep { !ref } @INC;
    my $cmd = sprintf '%s %s -e %s %s 2>&1', _q($^X), $inc, _q($code),
        join(' ', map { _q($_) } @args);
    my $out = qx{$cmd};
    return ($? >> 8, $out // '');
}

sub generate {
    my (%o) = @_;
    my $dir = tempdir() . '/' . ($o{name} || 'CmdApp');
    Punk::Generate->new(name => ($o{name} || 'CmdApp'), dir => $dir,
                        ($o{api} ? (api => $o{api}) : ()))->run;
    return $dir;
}

sub slurp { open my $f, '<', $_[0] or die $!; local $/; return <$f> }
sub spew  { open my $f, '>', $_[0] or die $!; print $f $_[1]; close $f }

# ---- punk routes -------------------------------------------------------------

{
    # `punk new` names its one route `home`, so a generated application
    # shows the NAME column from the start
    my $dir = generate();
    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0');
    like($out, qr/^METHOD\s+PATH\s+NAME\s+TARGET/m, 'it prints a header');
    like($out, qr{^GET\s+/\s+home\s+CmdApp::Controller::Web::Root::index}m,
        'a target string resolves to the sub it landed on');
    like($out, qr{/static/\*\s+static}, 'the static mount is listed');
    like($out, qr/^\d+ routes$/m, 'and a count');
}

{
    # ... and an application that names nothing prints exactly the table it
    # printed before names existed: no column, no shifted spacing
    my $dir = generate(name => 'CmdBare');
    my $cls = File::Spec->catfile($dir, 'lib', 'CmdBare.pm');
    my $src = slurp($cls);
    $src =~ s/\Q, { name => 'home' }\E//
        or die 'the generated app class did not look as expected';
    spew($cls, $src);

    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0 for an application that names nothing');
    like($out, qr/^METHOD\s+PATH\s+TARGET/m,
        'and prints no NAME column at all');
    like($out, qr{^GET\s+/\s+CmdBare::Controller::Web::Root::index}m,
        'so the target sits where it always did');
}

{
    # Named routes: the table is where a
    # person goes to find out what a name means, so `punk routes` shows the
    # column and filters on it. The column appears only when something is
    # named - the case above proves the unnamed table is unchanged.
    my $dir = generate();
    my $cls = File::Spec->catfile($dir, 'lib', 'CmdApp.pm');
    my $src = slurp($cls);
    # `punk new` already names its one route `home`; this adds a second so
    # the filter and the column have something to choose between
    my $add = join "\n",
        q{get '/' => 'Web::Root#index', { name => 'home' };},
        q{get '/health' => sub { $_[0]->json({ ok => 1 }) }, { name => 'health' };};
    $src =~ s/\Qget '\/' => 'Web::Root#index', { name => 'home' };\E/$add/
        or die 'the generated app class did not look as expected';
    spew($cls, $src);

    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0 with named routes');
    like($out, qr/^METHOD\s+PATH\s+NAME\s+TARGET/m,
        'the NAME column appears once a route has one');
    like($out, qr{^GET\s+/\s+home\s+CmdApp::Controller::Web::Root::index}m,
        'and the name sits between the path and the target');
    like($out, qr{^ANY\s+/static/\*\s+static}m,
        'an unnamed row leaves the column blank rather than shifting');

    my ($rc2, $one) = punk($dir, 'routes', '--name', 'health');
    is($rc2, 0, '--name exits 0');
    like($one, qr{^GET\s+/health\s+health}m, '--name selects its route');
    unlike($one, qr{^GET\s+/\s+home}m,       'and only that route');
    like($one, qr/^1 route$/m,               'the count agrees');

    my ($rc3, $none) = punk($dir, 'routes', '--name', 'nope');
    is($rc3, 0, '--name with no match still exits 0');
    like($none, qr/no matching routes/, 'and says so');
}

SKIP: {
    skip 'the fixture spec is missing', 5 unless -f $SPEC;
    my $dir = generate(name => 'CmdApi', api => $SPEC);
    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0 with an api mount');

    # Operations live in the mount, not the router: if these are missing the
    # command is only showing half the application.
    # the NAME column (an operationId) sits between the path and the target
    like($out, qr{^GET\s+/api/books\s+allBooks\s+CmdApi::Controller::API::Books::allBooks}m,
        'spec operations appear, under the mount prefix');
    like($out, qr{^POST\s+/api/books\s+addBook\s+\S*addBook}m,
        'and the write operation');

    SKIP: {
        # The generated app mounts /docs only when Open::API::UI is loadable,
        # and that needs Markdown::Simple, which is not a prerequisite. Without
        # it there is no docs route to name, so this asserts nothing rather
        # than failing - the same gate t/0610-docs-ui.t puts on the whole file.
        skip 'Open::API::UI (Template::Stencil + Markdown::Simple) not available', 1
            unless eval { require Open::API::UI; 1 };
        like($out, qr{^GET\s+/docs\s+native handler}m,
            'a C closure is named as one rather than by its .h file');
    }

    my ($rc2, $sorted) = punk($dir, 'routes', '--sort');
    is($rc2, 0, '--sort works');

    # an operationId IS a name - it is what url_for takes for that route, and
    # it shares the one namespace with the route names
    like($out, qr/^METHOD\s+PATH\s+NAME\s+TARGET/m,
        'an api mount gives the table a NAME column');
    my ($rc3, $one) = punk($dir, 'routes', '--name', 'allBooks');
    is($rc3, 0, '--name exits 0 for an operation');
    like($one, qr{^GET\s+/api/books\s+allBooks}m,
        '--name selects an api row by its operationId');
    like($one, qr/^1 route$/m, 'and only it');
}

# ---- punk doctor -------------------------------------------------------------

{
    my ($rc, $out) = punk($CWD, 'doctor');
    is($rc, 0, 'punk doctor exits 0 in a healthy tree');
    like($out, qr/^prerequisites$/m, 'it reports prerequisites');
    like($out, qr/^C ABIs$/m,        'and the C ABI tables');
    like($out, qr/Open::API \(oa_abi\)\s+v\d/,     'oa_abi with a version');
    like($out, qr/Hyperman \(hm_abi\)\s+v\d/,      'hm_abi with a version');
    like($out, qr/Template::Stencil \(st_abi\)\s+resolved/, 'st_abi resolved');
    like($out, qr/no problems found/, 'and a verdict');
}

{   # inside an application it adds that application's own report
    my $dir = generate(name => 'DocApp');
    my ($rc, $out) = punk($dir, 'doctor');
    like($out, qr/^application$/m,   'run inside an application it says so');
    like($out, qr/class\s+DocApp/,   'naming the class');
}

# ---- punk config check -------------------------------------------------------

{
    my $dir = generate(name => 'CfgApp');
    my ($rc, $out) = punk($dir, 'config', 'check');
    is($rc, 0, 'a generated configuration checks out');
    like($out, qr/^layers$/m, 'it lists the layers');
    like($out, qr/configuration is sound/, 'and says so');
}

{   # the case it exists for: every failure reported, not just the first
    my $dir = generate(name => 'SecApp');
    my $yml = File::Spec->catfile($dir, 'config', 'punk.yml');
    spew($yml, slurp($yml) . <<'YML');

database:
  password: { $env: PUNK_TEST_ABSENT_VAR }
mailer:
  key:   { $file: /no/such/secret/file }
  token: { $exec: [ punk-definitely-not-a-real-program ] }
YML
    my ($rc, $out) = punk($dir, 'config', 'check');
    is($rc, 1, 'unresolvable secrets exit non-zero - usable as a gate');
    like($out, qr/database\.password\s+\$env: PUNK_TEST_ABSENT_VAR is not set/,
        'the missing environment variable is named');
    like($out, qr/mailer\.key\s+\$file: \S+ does not exist/,
        'the missing file is named');
    like($out, qr/mailer\.token\s+\$exec: \S+ is not on PATH/,
        'the missing program is named');
    my $failed = () = $out =~ /FAILED/g;
    cmp_ok($failed, '>=', 3,
        'all three are reported, not just the one that would croak first');
}

{   # a secret that resolves is reported as resolving, and the value never
    # appears in the output
    my $dir = generate(name => 'OkApp');
    my $yml = File::Spec->catfile($dir, 'config', 'punk.yml');
    spew($yml, slurp($yml) . <<'YML');

database:
  password: { $env: PUNK_TEST_PRESENT_VAR }
YML
    local $ENV{PUNK_TEST_PRESENT_VAR} = 'sw0rdf1sh';
    my ($rc, $out) = punk($dir, 'config', 'check', '--dump');
    is($rc, 0, 'a resolvable secret checks out');
    like($out, qr/PUNK_TEST_PRESENT_VAR is set/, 'reported as set');
    unlike($out, qr/sw0rdf1sh/,
        'and the value itself never reaches the output');
    like($out, qr/\[redacted\]/, 'the dump shows it redacted');
}

# ---- punk api sync -----------------------------------------------------------

SKIP: {
    skip 'the fixture spec is missing', 9 unless -f $SPEC;
    my $dir = generate(name => 'SyncApp', api => $SPEC);

    {   # nothing to do, and the checker class is not mistaken for operations
        my ($rc, $out) = punk($dir, 'api', 'sync');
        is($rc, 0, 'api sync exits 0');
        like($out, qr/every operation in the spec is implemented/,
            'a freshly generated application is already in sync');
        unlike($out, qr/no operation in the spec/,
            'security checkers are not reported as orphaned operations');
    }

    # Implement one, then grow the spec.
    my $book = File::Spec->catfile($dir, qw(lib SyncApp Controller API Books.pm));
    my $src  = slurp($book);
    $src =~ s/\Qreturn \E\$c->status\(501\)->json\(\{[^}]*\}[^;]*;/return { mine => 1 };   # HAND WRITTEN/s;
    spew($book, $src);

    my $spec2 = File::Spec->catfile($dir, 'openapi.json');
    require File::Raw::JSON;
    my $doc = File::Raw::JSON::file_json_decode(slurp($spec2));
    $doc->{paths}{'/books/{id}/cover'} = {
        get => { operationId => 'getCover',
                 summary     => 'The cover image',
                 parameters  => [ { name => 'id', in => 'path',
                                    required => \1,
                                    schema => { type => 'string' } } ],
                 responses   => { 200 => { description => 'ok' } } },
    };
    spew($spec2, File::Raw::JSON::file_json_encode($doc));

    {
        my ($rc, $out) = punk($dir, 'api', 'sync', '--dry-run');
        is($rc, 0, 'a dry run exits 0');
        like($out, qr/would add 1 stub/, 'it reports what it would add');
        unlike(slurp($book), qr/getCover/, 'and writes nothing');
    }

    my ($rc, $out) = punk($dir, 'api', 'sync');
    like($out, qr/added 1 stub/, 'the real run adds it');
    like(slurp($book), qr/^sub getCover \{/m,
        'the new stub joins the controller its siblings are in');
    like(slurp($book), qr/HAND WRITTEN/,
        'and the implemented operation is untouched');

    # An operation the spec no longer declares is reported, never removed.
    delete $doc->{paths}{'/books/{id}/cover'};
    spew($spec2, File::Raw::JSON::file_json_encode($doc));
    (undef, my $out2) = punk($dir, 'api', 'sync');
    like($out2, qr/no operation in the spec \(left alone\)/,
        'a method the spec dropped is reported');
    like($out2, qr/getCover/, 'by name');
    like(slurp($book), qr/^sub getCover \{/m, 'and left in place');
}

# ---- punk console ------------------------------------------------------------

{
    my $dir = generate(name => 'ReplApp');
    my $inc = join ' ', map { '-I' . _q($_) } grep { !ref } @INC;
    my $out = qx{cd @{[ _q($dir) ]} && echo 'ref(\$app)' | @{[ _q($^X) ]} $inc @{[ _q($BIN) ]} console 2>&1};
    like($out, qr/punk console - ReplApp/, 'the console names the application');
    like($out, qr/'Punk::App'/,
        'and evaluates a line from a pipe - Term::ReadLine reads none');
}

# ---- usage and errors --------------------------------------------------------

{
    my ($rc, $out) = punk($CWD, 'help');
    is($rc, 0, 'punk help exits 0');
    like($out, qr/^\s+routes\s/m,  'listing routes');
    like($out, qr/^\s+api sync\s/m, 'and api sync');

    for my $c (qw(routes api config doctor console dev)) {
        my ($rc2, $usage) = punk($CWD, 'help', $c);
        is($rc2, 0, "punk help $c exits 0");
        like($usage, qr/^usage: punk \Q$c\E/m, "...and documents $c");
    }

    my ($rc3) = punk($CWD, 'help', 'nonsense');
    is($rc3, 2, 'an unknown help topic is a usage error');

    my ($rc4, $o4) = punk($CWD, 'api', 'wat');
    is($rc4, 2, 'api needs a known subcommand');
    like($o4, qr/expected 'sync'/, 'and says which');
}

{   # outside an application, the commands that need one say so
    my $empty = tempdir();
    for my $c ([qw(routes)], [qw(config check)], [qw(api sync)]) {
        my ($rc, $out) = punk($empty, @$c);
        is($rc, ($c->[0] eq 'routes' ? 1 : 2),
            "punk @$c outside an application fails");
        like($out, qr/no application found|no such file/,
            "...with a message that says why (@$c)");
    }
    my ($rc) = punk($empty, 'doctor');
    is($rc, 0, 'doctor still works outside an application');
}

END { chdir $CWD if $CWD }

# ---- punk new --sqitch ---------------------------------------------------------

{
    # an engine Sqitch has no project for is a usage error before anything
    # is written
    my $base = tempdir();
    my ($rc, $out) = punk($base, 'new', 'SqApp', '--dir', "$base/bad", '--sqitch', 'oracle');
    is($rc, 2, 'punk new --sqitch with an unknown engine is a usage error');
    like($out, qr/--sqitch needs an engine: sqlite, pg or mysql, not 'oracle'/, 'naming the three');
    ok(!-d "$base/bad", 'and nothing was generated');

    # with a real engine the application is generated either way; the Sqitch
    # half depends on Punk-Sqitch being installed, which this test does not
    # require - it accepts both outcomes and checks each is honest
    ($rc, $out) = punk($base, 'new', 'SqApp', '--dir', "$base/ok", '--sqitch', 'sqlite');
    ok(-f "$base/ok/app.psgi", 'the application is generated');
    if ($rc == 0) {
        # Punk-Sqitch keeps everything it owns under sqitch/
        like(slurp("$base/ok/sqitch/sqitch.plan"), qr/^%project=sqapp$/m,
            'Punk-Sqitch present: a project named for the application');
        like(slurp("$base/ok/sqitch/sqitch.conf"), qr/^\s*engine = sqlite$/m,
            'on the engine asked for');
    }
    else {
        is($rc, 1, 'Punk-Sqitch absent: exit 1, the application still written');
        like($out, qr/--sqitch needs Punk-Sqitch, which is not installed; once it is, run\n\n  punk sqitch init --engine sqlite/,
            'with the command to run once it is installed');
        ok(!-e "$base/ok/sqitch/sqitch.plan", 'and no half-made project');
    }
}

# ---- load_app ------------------------------------------------------------------
# The public form of what every application-loading command does, for a command
# in another distribution. Its one addition over the private one is `chdir`:
# app.psgi changes directory to the application root and everything relative in
# punk.yml is written for that, so a caller that will go on to open a database
# has to be left there.

{
    my $dir = generate(name => 'LoadApp');
    my $here = Cwd::getcwd();

    # in a child, because loading an application compiles its class and two of
    # them in one interpreter would collide
    my $code = <<'CHILD';
use Cwd ();
use Punk::Command ();
my $start = Cwd::getcwd();
my $app = Punk::Command->load_app(dir => $ARGV[0]);
print "class=$app->{class}\n";
print "root=$app->{root}\n";
print "psgi=", (ref $app->{psgi} eq 'CODE' ? 'code' : 'no'), "\n";
print "registrar=", ($app->{registrar} ? 'yes' : 'no'), "\n";
print "cwd_restored=", (Cwd::getcwd() eq $start ? 'yes' : 'no'), "\n";
CHILD
    my ($rc, $out) = run_perl($code, $dir);
    is($rc, 0, 'load_app loads a generated application');
    like($out, qr/^class=LoadApp$/m,  'the class out of app.psgi');
    # the root comes back resolved (/private/var, not /var, on darwin)
    my ($got_root) = $out =~ /^root=(.*)$/m;
    is($got_root, Cwd::abs_path($dir), 'the root it was found in');
    like($out, qr/^psgi=code$/m,      'the psgi coderef');
    like($out, qr/^registrar=yes$/m,  'and the registrar, which needs to_app');
    like($out, qr/^cwd_restored=yes$/m,
        'without chdir the caller gets its directory back');

    my $chdir = <<'CHILD';
use Cwd ();
use Punk::Command ();
my $app = Punk::Command->load_app(dir => $ARGV[0], chdir => 1);
print "cwd=", Cwd::getcwd(), "\n";
print "root=$app->{root}\n";
CHILD
    ($rc, $out) = run_perl($chdir, $dir);
    is($rc, 0, 'chdir => 1 loads the same way');
    my ($cwd) = $out =~ /^cwd=(.*)$/m;
    my ($root) = $out =~ /^root=(.*)$/m;
    is(Cwd::abs_path($cwd), Cwd::abs_path($root),
        'and leaves the process in the application root, where a relative '
      . 'dsn in punk.yml resolves');

    # the failure is a die, because a command body's die already becomes one
    # prefixed line through _fail
    my $missing = <<'CHILD';
use Punk::Command ();
my $app = eval { Punk::Command->load_app(dir => $ARGV[0]) };
print "err=$@";
CHILD
    ($rc, $out) = run_perl($missing, tempdir());
    like($out, qr/^err=no application found \(looked for app\.psgi upwards/m,
        'a directory with no application dies with the reason, unprefixed');
    unlike($out, qr/^err=punk:/m, 'the command prefix is the caller\'s to add');

    chdir $here;
}

done_testing();
