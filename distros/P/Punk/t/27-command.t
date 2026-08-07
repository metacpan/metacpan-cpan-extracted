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
    my $dir = generate();
    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0');
    like($out, qr/^METHOD\s+PATH\s+TARGET/m, 'it prints a header');
    like($out, qr{^GET\s+/\s+CmdApp::Controller::Web::Root::index}m,
        'a target string resolves to the sub it landed on');
    like($out, qr{/static/\*\s+static}, 'the static mount is listed');
    like($out, qr/^\d+ routes$/m, 'and a count');
}

SKIP: {
    skip 'the fixture spec is missing', 5 unless -f $SPEC;
    my $dir = generate(name => 'CmdApi', api => $SPEC);
    my ($rc, $out) = punk($dir, 'routes');
    is($rc, 0, 'punk routes exits 0 with an api mount');

    # Operations live in the mount, not the router: if these are missing the
    # command is only showing half the application.
    like($out, qr{^GET\s+/api/books\s+CmdApi::Controller::API::Books::allBooks}m,
        'spec operations appear, under the mount prefix');
    like($out, qr{^POST\s+/api/books\s+\S*addBook}m, 'and the write operation');

    SKIP: {
        # The generated app mounts /docs only when Open::API::UI is loadable,
        # and that needs Markdown::Simple, which is not a prerequisite. Without
        # it there is no docs route to name, so this asserts nothing rather
        # than failing - the same gate t/09-docs-ui.t puts on the whole file.
        skip 'Open::API::UI (Template::Stencil + Markdown::Simple) not available', 1
            unless eval { require Open::API::UI; 1 };
        like($out, qr{^GET\s+/docs\s+native handler}m,
            'a C closure is named as one rather than by its .h file');
    }

    my ($rc2, $sorted) = punk($dir, 'routes', '--sort');
    is($rc2, 0, '--sort works');
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

done_testing();
