use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

=pod

=head1 NAME

t/cli.t - SOW-03 public CLI contract tests

=head1 DESCRIPTION

This test file verifies that C<bin/pax> exposes only C<build> and C<run> to
users. Older diagnostics remain implementation internals and must not be
reachable as public subcommands. It also verifies Perl-style inline entrypoint
support via C<-I>, C<-M>, and C<-e> for the public build/run surface.

=cut

my $repo = abs_path("$FindBin::Bin/..");
my $pax = "$repo/bin/pax";
my $sow03_root = "$repo/t/tmp-sow03";
local $ENV{PAX_PROGRESS} = 0;
remove_tree($sow03_root) if -d $sow03_root;
make_path($sow03_root);

# Execute a CLI command with explicit stdout/stderr capture so the test can
# inspect machine-readable output without shell redirection races.
sub _run_with_redirect {
    my (%args) = @_;
    my $stdout_path = $args{stdout};
    my $stderr_path = $args{stderr};
    my $env = $args{env} // {};
    my $cwd = $args{cwd};
    my @cmd = @{ $args{cmd} // [] };

    die 'stdout path is required' if !defined $stdout_path;
    die 'stderr path is required' if !defined $stderr_path;
    die 'command is required' if !@cmd;

    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ($pid == 0) {
        if (defined $cwd) {
            chdir $cwd or die "cannot chdir to $cwd: $!";
        }
        while (my ($key, $value) = each %{$env}) {
            if (defined $value) {
                $ENV{$key} = $value;
            }
            else {
                delete $ENV{$key};
            }
        }
        open STDOUT, '>', $stdout_path or die "cannot open stdout redirect $stdout_path: $!";
        open STDERR, '>', $stderr_path or die "cannot open stderr redirect $stderr_path: $!";
        exec { $cmd[0] } @cmd or die "cannot exec @cmd: $!";
    }

    waitpid($pid, 0);
    return $? >> 8;
}

# Remove a temporary file or directory created by the CLI acceptance harness.
sub _cleanup_path {
    my ($path) = @_;
    return if !defined $path || !-e $path;
    if (-d $path) {
        remove_tree($path);
        return;
    }
    unlink $path or die "cannot remove $path: $!";
}

# Remove a generated standalone binary and its sibling C source when the test no
# longer needs them.
sub _cleanup_binary_artifact {
    my ($path) = @_;
    return if !defined $path;
    _cleanup_path($path) if -e $path;
    my $c_path = "$path.c";
    _cleanup_path($c_path) if -e $c_path;
}

my $help = `$^X $pax help`;
is($? >> 8, 0, 'pax help exits successfully');
like($help, qr/^usage:\n  pax build /, 'help starts with build usage');
like($help, qr/^  pax run /m, 'help includes run usage');
unlike($help, qr/\bpax (?:capture|standalone-build|app-build|bench|gatekeeper)\b/, 'help omits non-public commands');

my $old_cli = `$^X $pax capture --compact t/fixtures/simple.pl 2>&1`;
is($? >> 8, 2, 'removed public command exits with usage error');
like($old_cli, qr/unknown command: capture/, 'removed command reports unknown command');
like($old_cli, qr/^usage:\n  pax build /m, 'removed command prints SOW-03 usage');
unlike($old_cli, qr/\bpax standalone-build\b|\bpax app-build\b/, 'removed command usage stays minimal');

my $build_json = `$^X $pax build --compact --paxfile t/fixtures/paxfile.yml`;
is($? >> 8, 0, 'pax build exits successfully using paxfile defaults');
my $build = decode_json($build_json);
my $paxfile_binary = File::Spec->rel2abs("$repo/t/tmp-sow03/fixture-app");
is($build->{status}, 'built', 'build command creates standalone binary');
is($build->{standalone}{output_path}, $paxfile_binary, 'build command honors paxfile output');
ok(-x $build->{standalone}{output_path}, 'build output binary is executable');

my $run_output = `$^X $pax run --paxfile t/fixtures/paxfile.yml -- status`;
is($? >> 8, 0, 'pax run exits successfully using paxfile defaults');
is($run_output, "slowload-ready\n", 'run command executes the built standalone binary');

my $override_binary = File::Spec->rel2abs("$sow03_root/override-binary");
my $override_build_json = `$^X $pax build --compact --paxfile t/fixtures/paxfile.yml -o $override_binary`;
is($? >> 8, 0, 'pax build accepts -o output override');
my $override_build = decode_json($override_build_json);
is($override_build->{standalone}{output_path}, $override_binary, 'build command records overridden output path');
ok(-x $override_binary, 'overridden build output is executable');

my $override_run_output = `$^X $pax run --paxfile t/fixtures/paxfile.yml --output $override_binary -- asset`;
is($? >> 8, 0, 'pax run accepts --output override');
is($override_run_output, "embedded-fixture-asset\n", 'run command executes binary with embedded asset');

my $progress_json = "$sow03_root/progress-build.json";
my $progress_stderr = "$sow03_root/progress-build.stderr";
my $progress_rc = _run_with_redirect(
    env => { PAX_PROGRESS => 1 },
    stdout => $progress_json,
    stderr => $progress_stderr,
    cmd => [ $^X, $pax, 'build', '--compact', '--paxfile', 't/fixtures/paxfile.yml' ],
);
is($progress_rc, 0, 'pax build still succeeds when progress rundown is emitted by default');
open my $progress_fh, '<', $progress_stderr or die "cannot read progress stderr: $!";
my $progress_text = do { local $/; <$progress_fh> };
close $progress_fh;
like($progress_text, qr/pax build progress/, 'pax build progress output prints the task-board title');
like($progress_text, qr/\[ \] Resolve build inputs/, 'pax build progress output prints the full task list before work begins');
like($progress_text, qr/\[OK\] Discover Perl source units/, 'pax build progress output breaks out source discovery');
like($progress_text, qr/\[OK\] Compile entrypoint unit/, 'pax build progress output breaks out entrypoint compilation');
like($progress_text, qr/\[OK\] Compile application units/, 'pax build progress output breaks out application unit compilation');
like($progress_text, qr/Compile application units \(\d+\/\d+: lib:SlowLoad\.pm\)/, 'pax build progress output shows file-level application unit progress');
like($progress_text, qr/\[OK\] Compile dependency units/, 'pax build progress output breaks out dependency compilation');
like($progress_text, qr/\[OK\] Infer application metadata/, 'pax build progress output breaks out application metadata inference');
like($progress_text, qr/\[OK\] Analyze runtime dependencies/, 'pax build progress output breaks out runtime dependency analysis');
like($progress_text, qr/\[OK\] Write standalone manifest/, 'pax build progress output breaks out manifest emission');
like($progress_text, qr/\[OK\] Compile standalone launcher/, 'pax build progress output marks the launcher phase complete');
open my $progress_json_fh, '<', $progress_json or die "cannot read progress json: $!";
my $progress_payload = do { local $/; <$progress_json_fh> };
close $progress_json_fh;
my $progress_build = decode_json($progress_payload);
is($progress_build->{status}, 'built', 'pax build keeps machine-readable payload on stdout while progress prints on stderr');

my $quiet_json = "$sow03_root/quiet-build.json";
my $quiet_stderr = "$sow03_root/quiet-build.stderr";
my $quiet_rc = _run_with_redirect(
    env => { PAX_PROGRESS => 0 },
    stdout => $quiet_json,
    stderr => $quiet_stderr,
    cmd => [ $^X, $pax, 'build', '--compact', '--paxfile', 't/fixtures/paxfile.yml' ],
);
is($quiet_rc, 0, 'pax build still succeeds when progress rundown is disabled');
open my $quiet_fh, '<', $quiet_stderr or die "cannot read quiet stderr: $!";
my $quiet_text = do { local $/; <$quiet_fh> };
close $quiet_fh;
is($quiet_text, '', 'PAX_PROGRESS=0 suppresses the build rundown');

my $workdir = "$sow03_root/work";
make_path($workdir);
my $no_arg_binary = "$sow03_root/no-arg-binary";
open my $pfh, '>', "$workdir/paxfile.yml" or die "cannot write test paxfile: $!";
print {$pfh} join("\n",
    "name: no-arg-fixture",
    "entrypoint: $repo/t/fixtures/app_entry.pl",
    "output: $no_arg_binary",
    "libs:",
    "  - $repo/t/fixtures/app_lib",
    "assets:",
    "  - $repo/t/fixtures/app_assets/banner.txt",
    "",
);
close $pfh or die "cannot close test paxfile: $!";
my $no_arg_build_json = `cd $workdir && $^X $pax build --compact`;
is($? >> 8, 0, 'pax build with no arguments reads local paxfile.yml');
my $no_arg_build = decode_json($no_arg_build_json);
is($no_arg_build->{standalone}{output_path}, $no_arg_binary, 'no-argument build honors paxfile output');
ok(-x $no_arg_binary, 'no-argument build output is executable');
my $no_arg_run_output = `cd $workdir && $^X $pax run -- status`;
is($? >> 8, 0, 'pax run with no build arguments reads local paxfile.yml');
is($no_arg_run_output, "slowload-ready\n", 'no-argument run executes built standalone binary');

for my $early_artifact (
    $paxfile_binary,
    $override_binary,
    $no_arg_binary,
) {
    _cleanup_binary_artifact($early_artifact);
}
_cleanup_path($progress_json) if -e $progress_json;
_cleanup_path($progress_stderr) if -e $progress_stderr;
_cleanup_path($quiet_json) if -e $quiet_json;
_cleanup_path($quiet_stderr) if -e $quiet_stderr;

my $blank = "$sow03_root/blank";
make_path($blank);
my $self_binary = "$sow03_root/pax-self";
my $self_build_log = "$sow03_root/pax-self-build.json";
my $self_build_rc = _run_with_redirect(
    cwd => $blank,
    stdout => $self_build_log,
    stderr => File::Spec->catfile($sow03_root, 'pax-self-build.stderr'),
    cmd => [ $^X, $pax, 'build', '--compact', '-o', $self_binary, "$repo/bin/pax" ],
);
is($self_build_rc, 0, 'pax build -o output bin/pax succeeds from a blank directory without paxfile.yml');
ok(-x $self_binary, 'self-built pax binary is executable');
my $self_help = `cd $blank && env -i PATH=/nonexistent TMPDIR=/tmp $self_binary help`;
is($? >> 8, 0, 'self-built pax runs without source checkout in its working directory');
like($self_help, qr/^usage:\n  pax build /, 'self-built pax prints build usage');
unlike($self_help, qr/\bpax standalone-build\b|\bpax app-build\b|\bpax capture\b/, 'self-built pax keeps SOW-03 CLI surface');

my $self_run_binary = "$sow03_root/pax-self-run";
my $self_run_output = `cd $blank && $^X $pax run --compact -o $self_run_binary $repo/bin/pax -- help`;
is($? >> 8, 0, 'pax run bin/pax builds then runs self-built pax');
like($self_run_output, qr/^usage:\n  pax build /, 'pax run bin/pax emits self-built help output');
ok(-x $self_run_binary, 'pax run self-build writes requested binary');

my $isolated_json = `cd $repo && $^X $pax build --compact -o $sow03_root/isolated-app t/fixtures/app_entry.pl`;
is($? >> 8, 0, 'explicit entrypoint build ignores ambient repo paxfile defaults');
my $isolated_build = decode_json($isolated_json);
is($isolated_build->{standalone}{asset_count}, 0, 'explicit entrypoint build does not inherit repo paxfile assets');
is(($isolated_build->{standalone}{build_plan}{paxfile_applied} // JSON::PP::false), JSON::PP::false, 'explicit entrypoint build records paxfile as unapplied');

my $inline_lib_root = "$sow03_root/inline-lib";
my $inline_module_dir = "$inline_lib_root/Local";
make_path($inline_module_dir);
open my $inline_module_fh, '>', "$inline_module_dir/InlineDemo.pm" or die "cannot write inline fixture module: $!";
print {$inline_module_fh} <<'END_INLINE_MODULE';
package Local::InlineDemo;

use strict;
use warnings;

sub import {
    my ($class, @args) = @_;
    $ENV{PAX_INLINE_DEMO} = join('|', @args);
}

sub render {
    my ($class) = @_;
    return 'inline:' . ($ENV{PAX_INLINE_DEMO} // 'unset');
}

1;
END_INLINE_MODULE
close $inline_module_fh or die "cannot close inline fixture module: $!";

my $inline_binary = "$sow03_root/inline-app";
my $inline_build_json = `cd $repo && $^X $pax build --compact -o $inline_binary -I $inline_lib_root -MLocal::InlineDemo=alpha,beta -e 'print Local::InlineDemo->render'`;
is($? >> 8, 0, 'pax build accepts -I, -M, and -e without an entrypoint file');
my $inline_build = decode_json($inline_build_json);
is($inline_build->{status}, 'built', 'inline build reports success');
ok(-x $inline_binary, 'inline build writes an executable binary');
is(($inline_build->{standalone}{build_plan}{paxfile_applied} // JSON::PP::false), JSON::PP::false, 'inline build does not inherit ambient repo paxfile defaults');
my $inline_output = `env -i PATH=/nonexistent TMPDIR=/tmp $inline_binary`;
is($? >> 8, 0, 'inline standalone binary executes successfully');
is($inline_output, 'inline:alpha|beta', 'inline standalone binary honors imported module arguments');

# Reclaim earlier standalone artifacts before the nested self-host build. Each
# bundled-perl binary is large enough that keeping every intermediate around can
# exhaust CI or local acceptance volumes.
for my $old_artifact (
    $self_run_binary,
    $inline_binary,
) {
    _cleanup_binary_artifact($old_artifact);
}
_cleanup_path($self_build_log) if -e $self_build_log;
_cleanup_path(File::Spec->catfile($sow03_root, 'pax-self-build.stderr')) if -e File::Spec->catfile($sow03_root, 'pax-self-build.stderr');
remove_tree($blank);
make_path($blank);

my $inline_run_output = `cd $blank && $^X $pax run -I$inline_lib_root -MLocal::InlineDemo=gamma,delta -e 'print Local::InlineDemo->render'`;
is($? >> 8, 0, 'pax run accepts compact -I and -M forms with -e');
is($inline_run_output, 'inline:gamma|delta', 'inline pax run executes synthesized entrypoint');

my $nested_workdir = "$sow03_root/self-hosted-build";
make_path($nested_workdir);
my $nested_binary = "$nested_workdir/nested-app";
open my $nested_pfh, '>', "$nested_workdir/paxfile.yml" or die "cannot write nested paxfile: $!";
print {$nested_pfh} join("\n",
    "name: nested-app",
    "entrypoint: $repo/t/fixtures/app_entry.pl",
    "output: $nested_binary",
    "libs:",
    "  - $repo/t/fixtures/app_lib",
    "assets:",
    "  - $repo/t/fixtures/app_assets/banner.txt",
    "",
);
close $nested_pfh or die "cannot close nested paxfile: $!";
my $nested_build_json = `cd $nested_workdir && env -i PATH=/nonexistent TMPDIR=/tmp $self_binary build --compact`;
is($? >> 8, 0, 'self-built pax can build another standalone binary from paxfile defaults');
my $nested_build = decode_json($nested_build_json);
is($nested_build->{status}, 'built', 'self-built pax reports successful nested build');
ok(-x $nested_binary, 'self-built pax writes nested standalone binary');
my $nested_status = `env -i PATH=/nonexistent TMPDIR=/tmp $nested_binary status`;
is($? >> 8, 0, 'nested standalone binary built by self-built pax executes');
is($nested_status, "slowload-ready\n", 'nested standalone built by self-built pax returns expected output');

_cleanup_path($nested_binary);
_cleanup_binary_artifact($nested_binary);
remove_tree($nested_workdir);

my $standalone_input_binary = "$sow03_root/pax-standalone-input";
my $standalone_blank = "$sow03_root/standalone-input-work";
make_path($standalone_blank);
my $standalone_input_build_json = `cd $standalone_blank && env -i PATH=/nonexistent TMPDIR=/tmp PAX_PROGRESS=0 $self_binary build --compact -o $standalone_input_binary $self_binary`;
is($? >> 8, 0, 'self-built pax can rebuild from a standalone pax binary input');
my $standalone_input_build = decode_json($standalone_input_build_json);
is($standalone_input_build->{status}, 'built', 'standalone pax input rebuild reports success');
ok(-x $standalone_input_binary, 'standalone pax input rebuild writes an executable');
my $standalone_input_help = `env -i PATH=/nonexistent TMPDIR=/tmp $standalone_input_binary help`;
is($? >> 8, 0, 'rebuilt standalone pax binary from standalone input executes');
like($standalone_input_help, qr/^usage:\n  pax build /, 'rebuilt standalone pax binary from standalone input keeps minimal CLI');
remove_tree($standalone_blank);

my $shebang_root = "$sow03_root/shebang";
my $shebang_bin_dir = "$shebang_root/bin";
my $shebang_lib_dir = "$shebang_root/lib";
make_path($shebang_bin_dir, $shebang_lib_dir);
open my $shebang_module_fh, '>', "$shebang_lib_dir/ShebangDemo.pm" or die "cannot write shebang fixture module: $!";
print {$shebang_module_fh} <<'END_SHEBANG_MODULE';
package ShebangDemo;

use strict;
use warnings;

our $render = sub { return join q{|}, @ARGV; };
*render = $render;

1;
END_SHEBANG_MODULE
close $shebang_module_fh or die "cannot close shebang fixture module: $!";

my $shebang_script = "$shebang_bin_dir/shebang-demo.pl";
open my $shebang_script_fh, '>', $shebang_script or die "cannot write shebang fixture script: $!";
print {$shebang_script_fh} <<"END_SHEBANG_SCRIPT";
#!$self_binary
use strict;
use warnings;
use FindBin;
use lib "\$FindBin::Bin/../lib";
use ShebangDemo;

print "script=\$0\\n";
print "args=" . ShebangDemo::render() . "\\n";
END_SHEBANG_SCRIPT
close $shebang_script_fh or die "cannot close shebang fixture script: $!";
chmod 0755, $shebang_script or die "cannot chmod shebang fixture script: $!";

my $shebang_output = `env -i PATH=/nonexistent TMPDIR=/tmp $self_binary $shebang_script alpha beta`;
is($? >> 8, 0, 'self-built pax binary runs a shebang-target Perl script directly');
like($shebang_output, qr/^\Qscript=$shebang_script\E$/m, 'shebang execution sets $0 to the script path');
like($shebang_output, qr/^args=alpha\|beta$/m, 'shebang execution preserves @ARGV for the script');

done_testing;

=head1 TEST PLAN

This test covers the public C<build> and C<run> command surface, self-hosting,
interpreter mode, inline Perl execution flags, and progress-rundown behavior.

=head1 HOW TO RUN

  prove -lv t/cli.t
