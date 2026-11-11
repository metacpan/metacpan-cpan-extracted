#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Path ();
use Test::More;
use Punk::Command;

# The edges of the command line, in-process through the capture seam: a raw
# command that dies, returns a code or nothing; nested verbs with two
# subcommands and with one; list, defaulted and hidden options and the help
# they print; the hints a failure carries; an option spec Getopt refuses; a
# doctor probe that dies; routes filtered every way on a small application,
# an application with none, and application files that do not load; and the
# config command over a file that is sound, unparseable or missing a secret.

sub run_punk {
    my (@argv) = @_;
    my ($out, $err) = ('', '');
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    local $Punk::Command::OUT = $ofh;
    local $Punk::Command::ERR = $efh;
    my $code = Punk::Command->main(@argv);
    close $ofh; close $efh;
    return ($code, $out, $err);
}
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }

# ---- a raw command owns its argv ------------------------------------------------
Punk::Command->register('t-raw' => {
    hidden => 1, raw => 1, usage => '<verb>', desc => 'an adapted CLI',
    code => sub { my ($o, @a) = @_; die "boom\n" if @a && $a[0] eq 'die'; return @a ? 3 : undef },
}, 'Owner::Raw');
{
    my ($c, $out, $err) = run_punk('t-raw');
    is($c, 0, 'a raw command returning nothing exits 0');
    ($c) = run_punk('t-raw', 'x');
    is($c, 3, 'and its own code otherwise');
    ($c, $out, $err) = run_punk('t-raw', 'die');
    is($c, 1, 'a raw command that dies exits 1');
    like($err, qr/^punk t-raw: boom$/m, 'with the error as one prefixed line');
    ($c, $out) = run_punk('help', 't-raw');
    like($out, qr/^usage: punk t-raw <verb>$/m, 'its help is its own usage line');
    like($out, qr/^an adapted CLI$/m, 'its description');
    like($out, qr/see `punk t-raw help` for its commands/, 'and where the rest is');
}

# ---- nested verbs ------------------------------------------------------------------
Punk::Command->register('t-nest' => {
    hidden => 1,
    commands => {
        alpha => { abstract => 'the first', code => sub { 7 } },
        beta  => { code => sub { 8 } },
    },
}, 'Owner::Nest');
{
    my ($c, $out, $err) = run_punk('t-nest');
    is($c, 2, 'a nested command without a verb is a usage error');
    like($err, qr/^usage: punk t-nest \[options\]$/m, 'with its usage');
    like($err, qr/^commands:\n  alpha  the first\n  beta\s*$/m, 'and the verbs listed');
    ($c, $out, $err) = run_punk('t-nest', 'gamma');
    is($c, 2, 'an unknown verb is a usage error');
    like($err, qr/unknown subcommand 'gamma' \(expected one of: alpha, beta\)/, 'naming the ones there are');
    ($c) = run_punk('t-nest', 'alpha');
    is($c, 7, 'a known verb runs');
    ($c) = run_punk('t-nest', 'beta');
    is($c, 8, 'any of them');
}
Punk::Command->register('t-one' => {
    hidden => 1,
    commands => { only => { usage => '<thing>', code => sub { 9 } } },
}, 'Owner::One');
{
    my ($c, $out, $err) = run_punk('t-one', 'zzz');
    is($c, 2, 'a wrong verb where there is one choice is a usage error');
    like($err, qr/^punk t-one: expected 'only'$/m, 'which names it');
    ($c, $out) = run_punk('help', 't-one');
    like($out, qr/^usage: punk t-one only <thing>$/m, 'the help spells the one verb out');
    ($c) = run_punk('t-one', 'only');
    is($c, 9, 'and it runs');
}

# ---- list, defaulted and hidden options ------------------------------------------
Punk::Command->register('t-tags' => {
    hidden => 1,
    options => [
        { spec => 'tag=s@', arg => 'T', doc => 'a tag', default => [ 'z' ] },
        { spec => 'n=i', doc => 'a count', default => 5 },
        { spec => 'quiet-ish', doc => 'hushed' },
        { spec => 'secret', hidden => 1 },
    ],
    examples => [ 'punk t-tags --tag x' ],
    code => sub {
        my ($o) = @_;
        print join(',', @{ $o->{tag} }), " n=$o->{n}", ($o->{quiet_ish} ? ' quiet' : ''), "\n";
        return 0;
    },
}, 'Owner::Tags');
{
    my ($c, $out) = run_punk('t-tags', '--tag', 'a', '--tag', 'b', '--n', '2', '--quiet-ish');
    is($c, 0, 'list options run');
    is($out, "z,a,b n=2 quiet\n", 'the list grows past its default, the count replaces its default, the hyphen is an underscore');
    ($c, $out) = run_punk('t-tags');
    is($out, "z n=5\n", 'with nothing given the defaults stand');
    ($c, $out) = run_punk('help', 't-tags');
    like($out, qr/^  --tag T\s+a tag$/m, 'a list option shows its argument');
    like($out, qr/^  --n\s+a count \(default: 5\)$/m, 'a scalar default is shown');
    like($out, qr/^  --quiet-ish\s+hushed$/m, 'an underscore is shown as a hyphen');
    unlike($out, qr/--secret/, 'a hidden option is not shown');
    like($out, qr/^examples:\n  punk t-tags --tag x$/m, 'and the examples are');
}

# ---- hints on a failure -----------------------------------------------------------
Punk::Command->register('t-hint' => {
    hidden => 1,
    hints => [ [ qr/disk/, 'free some space' ], [ qr/network/, 'check the cable' ] ],
    code => sub { die "Punk::Generate: the disk is full at /x/y.pm line 3.\n" },
}, 'Owner::Hint');
{
    my ($c, $out, $err) = run_punk('t-hint');
    is($c, 1, 'a dying command exits 1');
    like($err, qr/^punk t-hint: the disk is full$/m, 'the error loses its location and the generator prefix');
    like($err, qr/^  free some space$/m, 'the hint that matches is printed');
    unlike($err, qr/cable/, 'and the one that does not is not');
}

# ---- an option spec Getopt refuses -------------------------------------------------
Punk::Command->register('t-badopt' => {
    hidden => 1, options => [ { spec => 'bad==s' } ], code => sub { 0 },
}, 'Owner::Bad');
{
    my ($c, $out, $err) = run_punk('t-badopt');
    is($c, 2, 'a spec Getopt cannot parse is a usage error');
    like($err, qr/^punk t-badopt: /m, 'reported with the command prefix');
}

# ---- a doctor probe that dies ------------------------------------------------------
Punk::Command->register_doctor('t-dies' => sub { die "the probe broke at /x.pm line 9.\n" }, 'Owner::Dies');
{
    my ($c, $out) = run_punk('doctor');
    like($out, qr/t-dies\s+the probe broke\s+<- FAILED/, 'a dying probe is a FAILED row carrying its message');
}

# ---- routes on a small application ------------------------------------------------
my $base = File::Temp::tempdir(CLEANUP => 1);
sub app_dir {
    my ($name, $psgi, %files) = @_;
    my $dir = "$base/$name";
    File::Path::make_path("$dir/root", "$dir/lib");
    (my $text = $psgi) =~ s{__ROOT__}{$dir/root}g;
    $text =~ s{__LIB__}{$dir/lib}g;
    spew("$dir/app.psgi", $text);
    spew("$dir/$_", $files{$_}) for keys %files;
    return $dir;
}
# an application loads once per process, so every invocation gets its own
my $n = 0;
sub routes_app {
    $n++;
    return app_dir("routes$n", <<"PSGI");
use strict;
use warnings;
package RoutesApp$n;
use Punk;
get  '/a'      => sub { \$_[0]->text('a') }, { name => 'a' };
post '/b/:id'  => sub { \$_[0]->text('b') };
websocket '/ws' => sub { };
static '/s' => '__ROOT__';
RoutesApp$n->to_app;
PSGI
}
sub routes_out {
    my (@args) = @_;
    my ($c, $out, $err) = run_punk('routes', '--dir', routes_app(), @args);
    diag $err if $c;
    return $out;
}
{
    my ($c, $out, $err) = run_punk('routes', '--dir', routes_app());
    is($c, 0, 'routes on a hand-written application exits 0') or diag $err;
    like($out, qr{^GET\s+/a\s+a\s+}m, 'the named route shows its name');
    like($out, qr{^POST\s+/b/:id\s}m, 'the unnamed one its path');
    like($out, qr{^WS\s+/ws\s}m, 'the websocket route, beside the GET that upgrades');
    like($out, qr{^ANY\s+/s/\*\s+static .*root}m, 'the static mount');
    like($out, qr/^5 routes$/m, 'five in all');
    like(routes_out('--method', 'post'), qr/^1 route$/m, '--method filters, in any case');
    like(routes_out('--path', '/b/*'), qr{/b/:id.*\n\n1 route}s, '--path takes a glob, * within a segment');
    like(routes_out('--path', '/**'), qr/^5 routes$/m, 'and ** across segments');
    like(routes_out('--kind', 'ws'), qr{^WS\b.*\n\n1 route$}m, '--kind filters');
    like(routes_out('--name', 'a'), qr{^GET\s+/a\b.*\n\n1 route$}m, '--name filters');
    is(routes_out('--method', 'TRACE'), "no matching routes\n", 'a filter that matches nothing says so');
    like(routes_out('--sort'), qr{/a.*\n.*/b/:id.*\n.*/s/\*.*\n.*/ws.*\n.*/ws}s, '--sort orders by path');
    my $json = routes_out('--json');
    like($json, qr/^\[\{/, '--json prints a list of records');
    like($json, qr/"kind":"ws"/, 'each with its kind');
}
{
    my $empty = app_dir('empty', "package EmptyApp;\nuse Punk;\nEmptyApp->to_app;\n");
    my ($c, $out) = run_punk('routes', '--dir', $empty);
    is($c, 0, 'an application with no routes exits 0');
    is($out, "no routes\n", 'and says so');
}
{
    my $dies = app_dir('dies', "die \"nope\\n\";\n# Boom->to_app\n");
    my ($c, $out, $err) = run_punk('routes', '--dir', $dies);
    is($c, 1, 'an app.psgi that dies exits 1');
    like($err, qr/app\.psgi did not load: nope/, 'naming the error');
    my $nocode = app_dir('nocode', "package NoCode;\n1;\n# NoCode->to_app\n");
    ($c, $out, $err) = run_punk('routes', '--dir', $nocode);
    like($err, qr/did not load/, 'one that returns no coderef did not load either');
    my $plain = app_dir('plain', "package Plain;\nsub { [ 200, [], [ 'x' ] ] };\n# Plain->to_app\n");
    ($c, $out, $err) = run_punk('routes', '--dir', $plain);
    like($err, qr/Plain is not a Punk application/, 'a plain PSGI app is not a Punk one');
    my $noclass = app_dir('noclass', "sub { [ 200, [], [ 'x' ] ] };\n");
    ($c, $out, $err) = run_punk('routes', '--dir', $noclass);
    like($err, qr/cannot work out the application class/, 'and a file naming no class is refused');
    my $used = app_dir('used', "use lib '__LIB__';\nuse UseApp;\nUseApp::app();\n",
        'lib/UseApp.pm' => "package UseApp;\nuse Punk;\nget '/u' => sub { \$_[0]->text('u') };\nsub app { UseApp->to_app }\n1;\n");
    ($c, $out, $err) = run_punk('routes', '--dir', $used);
    is($c, 0, 'the class can come from the use line') or diag $err;
    like($out, qr{^GET\s+/u\s}m, 'and the routes are read');
    ($c, $out, $err) = run_punk('routes', '--dir', "$base/nowhere");
    is($c, 1, 'a directory with no application exits 1');
    like($err, qr/no application found/, 'and says so');
}

# ---- config ------------------------------------------------------------------------
SKIP: {
    skip 'YAML::XS is not installed', 16 unless eval { require YAML::XS; 1 };
    my $capp = app_dir('cfg', "package CfgApp;\nuse Punk;\nCfgApp->to_app;\n");
    my ($c, $out, $err) = run_punk('config', 'check', '--dir', "$base/nowhere");
    is($c, 2, 'config with no application exits 2');
    like($err, qr/no application found/, 'and says so');
    ($c, $out, $err) = run_punk('config', 'check', '--dir', $capp);
    is($c, 2, 'config with no file exits 2');
    like($err, qr/no such file: .*punk\.yml/, 'naming the file it looked for');
    File::Path::make_path("$capp/config");
    spew("$capp/config/punk.yml", "host: https://cfg.example\n");
    ($c, $out, $err) = run_punk('config', 'check', '--dir', $capp, '--env', 'test');
    is($c, 0, 'a sound file exits 0') or diag $err;
    like($out, qr/^env\s+test$/m, 'with the environment');
    like($out, qr/^  base\s+\S*punk\.yml$/m, 'the base layer present');
    like($out, qr/^- test\s+\S*punk\.test\.yml$/m, 'the environment layer absent, marked');
    like($out, qr/^no secret references$/m, 'no secrets');
    like($out, qr/^configuration is sound$/m, 'and the verdict');
    ($c, $out) = run_punk('config', 'check', '--dir', $capp, '--env', 'test', '--dump');
    like($out, qr/resolved \(secrets redacted\)\n.*cfg\.example/s, '--dump prints the resolved mapping');
    spew("$capp/config/punk.test.yml", "token: { \$env: PUNK_CFG_NOT_SET_X }\n");
    ($c, $out) = run_punk('config', 'check', '--dir', $capp, '--env', 'test');
    is($c, 1, 'an unresolvable secret exits 1');
    like($out, qr/token\s+\$env: .*FAILED/, 'the secret row is FAILED');
    like($out, qr/Punk::Config->load\s+.*not set\s+<- FAILED/, 'and the load fails on it too');
    spew("$capp/config/punk.test.yml", "a: [\n");
    ($c, $out) = run_punk('config', 'check', '--dir', $capp, '--env', 'test');
    is($c, 1, 'an unparseable layer exits 1');
    like($out, qr/UNPARSEABLE/, 'and is named');
}

done_testing;
