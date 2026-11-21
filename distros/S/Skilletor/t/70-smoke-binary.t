#!/usr/bin/env perl
# The keeper of scripts/binary-smoke.sh's expectation (skill perl-par-binary-release): the
# bundle's dzil-binary workflow smokes each packed binary on a clean machine against
# t/data/smoke/expected.txt. This test runs the same script with the Perl CLI from lib/ in place
# of the binary, so the transcript is what the Perl code writes and the smoke cannot rot.
# Regenerate after a change to the CLI's output (then review the diff):
#   SKILLETOR_SMOKE_UPDATE=1 prove -l t/70-smoke-binary.t
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd ();
use Path::Tiny qw( path tempdir );

my $dist = path( $FindBin::Bin, '..' )->realpath;
my $script = $dist->child( 'scripts', 'binary-smoke.sh' );
plan skip_all => 'needs scripts/binary-smoke.sh and package.json (a skilletor checkout)'
  unless $script->is_file && $dist->child('package.json')->is_file;
plan skip_all => 'a Unix shell test (the Windows smoke runs in the workflow)' if $^O eq 'MSWin32';
plan skip_all => 'needs bash' unless grep { -x "$_/bash" } split /:/, $ENV{PATH} // '';

# The stand-in binary: this perl running script/skilletor from lib/, its module path baked in,
# since the script runs the binary under `env -i`.
sub sq { my $s = shift; $s =~ s/'/'\\''/g; "'$s'" }
my $tmp  = tempdir;
my $base = 'skilletor-smoke-linux-x86_64';
my $bin  = $tmp->child($base);
my $perl5lib = join ':', $dist->child('lib'), map { path($_)->absolute } grep { length } split /:/, $ENV{PERL5LIB} // '';
$bin->spew_raw( "#!/bin/sh\nPERL5LIB=".sq($perl5lib)." exec ".sq($^X).' '.sq( $dist->child( 'script', 'skilletor' ) )." \"\$\@\"\n" );
$bin->chmod(0755);

# The smoke's shell keeps its own tools, but the CLI sees an empty PATH. The stand-in names this
# perl absolutely; a real packed binary therefore gets the same no-system-Perl/no-Node proof.
my $runtime_path = $tmp->child('runtime-path');
my $smoke_tmp = $tmp->child('tmp');
$runtime_path->mkpath;
$smoke_tmp->mkpath;
is_deeply( [ $runtime_path->children ], [], 'the runtime PATH is empty' );
local $ENV{SKILLETOR_SMOKE_PATH} = "$runtime_path";
local $ENV{TMPDIR} = "$smoke_tmp";    # the smoke shell's own mktemp; the runtime gets its child
local $ENV{SKILLETOR_SMOKE_OFFLINE} = 1;    # no network here: the workflow's smoke proves https

# The bundle's Linux smoke mounts the binary read-only, made executable on the host: a chmod of it
# fails there. A non-root test cannot make that mount, so a chmod first on the smoke shell's PATH
# refuses the stand-in the same way and hands every other file to the real one.
my ($real_chmod) = grep { -x } map { "$_/chmod" } split /:/, $ENV{PATH} // '';
my $ro_bin = $tmp->child('ro-bin');
$ro_bin->mkpath;
$ro_bin->child('chmod')->spew_raw( <<"SH" );
#!/bin/sh
for a in "\$@"; do
  case \$a in */$base) echo "chmod: changing permissions of '\$a': Read-only file system" >&2; exit 1 ;; esac
done
exec @{[ sq( $real_chmod // 'false' ) ]} "\$@"
SH
$ro_bin->child('chmod')->chmod(0755);
local $ENV{PATH} = "$ro_bin:$ENV{PATH}";

# Poison every ambient root the CLI could otherwise consult. binary-smoke.sh's env -i must replace
# HOME, harness homes, git and temporary paths, and drop config/project/plugin roots and PERL5LIB.
my $ambient = $tmp->child('ambient');
$ambient->child('claude')->mkpath;
$ambient->child( 'claude', 'skilletor.json' )->spew_raw('{ broken ambient config');
$ambient->child('gitconfig')->spew_raw("[broken\n");
my %ambient = (
  HOME                  => $ambient->child('home')."",
  CLAUDE_CONFIG_DIR     => $ambient->child('claude')."",
  CODEX_HOME            => $ambient->child('codex')."",
  HERMES_HOME           => $ambient->child('hermes')."",
  CLAUDE_PROJECT_DIR    => $ambient->child('claude-project')."",
  SKILLETOR_PROJECT_DIR => $ambient->child('skilletor-project')."",
  CLAUDE_PLUGIN_ROOT    => $ambient->child('plugin')."",
  SKILLETOR_BIN         => $ambient->child('bin')."",
  GIT_CONFIG_GLOBAL     => $ambient->child('gitconfig')."",
  GIT_CONFIG_SYSTEM     => $ambient->child('gitconfig')."",
  GIT_CONFIG_NOSYSTEM   => 0,
  GIT_DIR               => $ambient->child('git-dir')."",
  GIT_WORK_TREE         => $ambient->child('git-work-tree')."",
  GIT_INDEX_FILE        => $ambient->child('git-index')."",
  TMP                   => $ambient->child('tmp')."",
  TEMP                  => $ambient->child('temp')."",
  PAR_GLOBAL_TEMP       => $ambient->child('par')."",
  PERL5LIB              => $ambient->child('perl5lib')."",
);
my @ambient_keys = sort keys %ambient;
local @ENV{@ambient_keys} = @ambient{@ambient_keys};

my $cwd = Cwd::getcwd();
chdir $dist or die "chdir $dist: $!";
my $out = qx{bash scripts/binary-smoke.sh @{[ sq($bin) ]} 2>&1};
my $rc  = $? >> 8;
chdir $cwd or die "chdir $cwd: $!";

is( $rc, 0, 'scripts/binary-smoke.sh passes with the Perl CLI from lib/' )
  or diag $out, "\nregenerate the expectation: SKILLETOR_SMOKE_UPDATE=1 prove -l t/70-smoke-binary.t";
if ( $ENV{SKILLETOR_SMOKE_UPDATE} ) {
  like( $out, qr/^smoke: transcript written/m, 'the expectation is written' );
}
else {
  like( $out, qr/^smoke all ported commands and hooks: OK/m, 'the transcript equals t/data/smoke/expected.txt' );
  like( $out, qr/^smoke https url source: SKIPPED \(SKILLETOR_SMOKE_OFFLINE\)$/m, 'the https proof is left to the workflow' );
  like( $out, qr/^smoke: OK$/m, 'every smoke stage passes' );
}

# The expectation covers what the smoke claims: every ported command really ran, the rendered
# template, the url source's warning, the background sync's report handed out by the next prompt,
# and both moves into a checkout.
my $expected = $dist->child( 't', 'data', 'smoke', 'expected.txt' );
ok( $expected->is_file, 't/data/smoke/expected.txt exists' );
my $text = $expected->is_file ? $expected->slurp_raw : '';
like( $text, qr/^=== add a local source\n--- stdout\nadded source extra \(\{"local":"<work>\/home\/extra-src"\}\)\n.*?^--- exit 0$/ms,
  'the expectation proves add ran successfully' );
like( $text, qr/^=== trust an existing source\n--- stdout\ntrusted source loc \(local <work>\/home\/src\)\n--- stderr\n--- exit 0$/m,
  'the expectation proves trust ran successfully' );
like( $text, qr/^=== trust state after add and trust\n\{\n  "extra": \{\n    "kind": "local",\n    "address": "<work>\/home\/extra-src"\n  \},\n  "loc": \{\n    "kind": "local",\n    "address": "<work>\/home\/src"\n  \}\n\}$/m,
  'the expectation holds the trust state written by add and trust' );
like( $text, qr/^=== source list after add\n--- stdout\n(?:(?!^=== ).)*^extra \[user\] \{"local":"<work>\/home\/extra-src"\}\n(?:(?!^=== ).)*^--- exit 0$/ms,
  'the expectation proves source list saw the added source' );
like( $text, qr/^=== available from the added source\n--- stdout\n  skill extra\@extra — Extra smoke skill\n--- stderr\n--- exit 0$/m,
  'the expectation proves available read the added source' );
like( $text, qr/^=== install from the added source\n--- stdout\n(?:(?!^=== ).)*^  \+ skills\/extra \(active now\)\n(?:(?!^=== ).)*^--- exit 0$/ms,
  'the expectation proves install added the item' );
like( $text, qr/^=== installed extra skill: \.claude\/skills\/extra\/SKILL\.md\n---\nname: extra\ndescription: Extra smoke skill\n---\nExtra smoke body\.$/m,
  'the expectation holds the item installed by the command' );
like( $text, qr/^=== uninstall from the added source\n--- stdout\n(?:(?!^=== ).)*^  - skills\/extra \(removed\)\n(?:(?!^=== ).)*^--- exit 0$/ms,
  'the expectation proves uninstall removed the item' );
like( $text, qr/^=== extra skill after uninstall\n\(absent\)$/m,
  'the expectation proves the installed file is gone' );
like( $text, qr/^=== remove the added source\n--- stdout\n(?:(?!^=== ).)*^--- exit 0$/ms,
  'the expectation proves source remove ran successfully' );
like( $text, qr/^=== source extra after removal\n\(absent\)$/m,
  'the expectation proves source remove edited the config' );
like( $text, qr/^Hello WORLD from loc \(claude, user\)\.$/m, 'the expectation holds the rendered template' );
like( $text, qr/^  warning: source web: url source https:\/\/127\.0\.0\.1:1\/skills\.tar\.gz failed: /m,
  "the expectation holds the url source's warning" );
like( $text, qr/^=== the next prompt there: the background sync's pending report\n--- stdout\n\{"systemMessage":"skilletor: [^\n]*"hookEventName":"UserPromptSubmit"/m,
  "the expectation holds the background sync's pending report" );
like( $text, qr/^\{"systemMessage":"skilletor: [^"\n]* in <work>\/checkouts\/cwd-changed"\}$/m,
  'the expectation holds the cwd-changed sync of its checkout' );
like( $text, qr/^\{"systemMessage":"skilletor: [^"\n]* in <work>\/checkouts\/post-tool-use","hookSpecificOutput":\{"hookEventName":"PostToolUse"/m,
  'the expectation holds the post-tool-use sync of its checkout' );

done_testing;
