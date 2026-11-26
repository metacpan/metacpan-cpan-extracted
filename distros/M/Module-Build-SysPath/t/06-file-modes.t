#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Copy::Recursive 'dircopy';
use File::Temp;
use FindBin '$Bin';
use Path::Tiny 'path';
use POSIX ();

my $temporary = Path::Tiny->tempdir('syspath-modes-XXXXXXXX');
my $dist = $temporary->child('distribution');
my $system = $temporary->child('system');
ok(dircopy(path($Bin, 'tdirs', 'Acme-Test-SysPath'), $dist), 'copy distribution');
my $original_build = $dist->child('Build.PL')->slurp;

# Keep both installed payloads and the checksum store inside the temporary root.
$dist->child('TestPaths.pm')->spew(<<'PERL');
use Sys::Path::SPc;
use File::Spec;
no warnings 'redefine';
for my $type (Sys::Path::SPc->_path_types) {
    no strict 'refs';
    *{"Sys::Path::SPc::$type"} = sub {
        File::Spec->catdir($ENV{SYSPATH_TEST_ROOT}, $type);
    };
}
if ($ENV{SYSPATH_TEST_REMOVE_AFTER_COPY}) {
    require Module::Build;
    # Module::Build inherits ACTION_install; \&Module::Build::ACTION_install
    # would be a stub resolving to this wrapper and recurse without bound.
    my $install = Module::Build->can('ACTION_install') or die;
    *Module::Build::ACTION_install = sub {
        $install->(@_);
        unlink($ENV{SYSPATH_TEST_REMOVE_AFTER_COPY}) or die $!;
    };
}
1;
PERL
$system->child('sharedstatedir', 'syspath')->mkpath;
local $ENV{SYSPATH_TEST_ROOT} = "$system";
my @inc = map { '-I'.path($_)->absolute } @INC;
push @inc, '-I'.path($Bin, 'lib')->absolute, '-I'.$dist, '-MTestPaths';

sub run_build {
    my ($input, @args) = @_;
    my $stdin = File::Temp->new;
    print {$stdin} $input;
    seek($stdin, 0, 0) or die $!;
    my $pid = open(my $out, '-|');
    die $! if not defined $pid;
    if (not $pid) {
        # Never return into the test script from the child: a die here would be
        # caught by the surrounding subtest and the child would keep forking.
        eval {
            local $ENV{PERL_MM_USE_DEFAULT} = 0;
            open(STDIN, '<&', $stdin) or die $!;
            open(STDERR, '>&', STDOUT) or die $!;
            chdir($dist) or die $!;
            exec $^X, @inc, @args;
            die "exec: $!";
        };
        print "child setup failed: $@";
        POSIX::_exit(127);
    }
    local $/;
    my $output = <$out>;
    close $out;
    return ($?, $output);
}

sub configure {
    my ($declaration) = @_;
    my $build = $original_build;
    $build =~ s/(module_name\s*=>)/file_modes => $declaration,\n    $1/;
    $build =~ s/(module_name\s*=>)/sharedstatedir_files => { 'state\/seed' => 1 },\n    $1/;
    $dist->child('Build.PL')->spew($build);
    return run_build('', 'Build.PL', '--install_base='.$system.'/perl');
}

subtest 'validate exact selected payload declarations' => sub {
    for my $case (
        ['[]', qr/file_modes.*hash/i, 'hash required'],
        ["{ 'conf/acme-test-syspath.cfg' => -1 }", qr/file_modes.*mode/i, 'negative'],
        ["{ 'conf/acme-test-syspath.cfg' => 1.5 }", qr/file_modes.*mode/i, 'fraction'],
        ["{ 'conf/acme-test-syspath.cfg' => 01000 }", qr/file_modes.*mode/i, 'special bits'],
        ["{ 'conf/acme-test-syspath.cfg' => '0440' }", qr/file_modes.*mode/i, 'quoted octal'],
        [
            "{ 'conf/acme-test-syspath.cfg' => 0600, './conf/acme-test-syspath.cfg' => 0600 }",
            qr/file_modes.*more than once/i, 'duplicate file',
        ],
        ["{ '/etc/secret' => 0600 }", qr/file_modes.*relative/i, 'absolute path'],
        ["{ '../secret' => 0600 }", qr/file_modes.*relative/i, 'outside root'],
        ["{ 'conf/missing' => 0600 }", qr/file_modes.*selected/i, 'unselected file'],
        ["{ 'conf' => 0600 }", qr/file_modes.*selected/i, 'directory'],
        ["{ 'state/acme-state/.exists' => 0600 }", qr/file_modes.*selected/i, 'directory marker'],
    ) {
        my ($status, $output) = configure($case->[0]);
        isnt($status, 0, "reject $case->[2]");
        like($output, $case->[1], 'actionable declaration error');
    }
    my ($status, $output) = configure(
        "{ 'conf/acme-test-syspath.cfg' => 0000, 'share/share' => 0777 }",
    );
    is($status, 0, 'accept permission boundaries') or diag $output;
};

sub mode_is {
    my ($file, $mode, $description) = @_;
    my @stat = stat($file);
    is(@stat ? sprintf('%04o', $stat[2] & 0777) : undef,
        sprintf('%04o', $mode), $description);
}

sub install_ok {
    my ($answer, @args) = @_;
    my ($status, $output) = run_build($answer, 'Build', 'install', @args);
    is($status, 0, 'install succeeds') or diag $output;
    return $output;
}

sub ship_config {
    my ($content) = @_;
    $dist->child('conf', 'acme-test-syspath.cfg')->spew($content);
    # Module::Build compares mtimes; same-second edits must rebuild too.
    my $built = $dist->child('blib', 'sysconfdir', 'acme-test-syspath.cfg');
    $built->remove if $built->exists;
}

subtest 'final modes for installed payloads and configuration variants' => sub {
    $dist->child('conf', 'public.cfg')->spew("ordinary configuration\n");
    $dist->child('state', 'seed')->spew("initial state\n");
    my $manifest = $dist->child('MANIFEST');
    # Release distributions ship the manifest read-only.
    my @manifest_stat = stat($manifest) or die "cannot stat '$manifest': $!";
    chmod(($manifest_stat[2] & 07777) | 0200, $manifest)
        or die "cannot chmod '$manifest': $!";
    $manifest->append("conf/public.cfg\nstate/seed\n");
    my $declaration = <<'PERL';
{
    './conf/acme-test-syspath.cfg' => 0640,
    'share/share' => 0640,
    'srv/srv.file' => 0777,
}
PERL
    my ($status, $output) = configure($declaration);
    is($status, 0, 'configure declared modes') or diag $output;
    install_ok('');
    my $config = $system->child('sysconfdir', 'acme-test-syspath.cfg');
    my $public = $system->child('sysconfdir', 'public.cfg');
    my $explicit = $system->child('datadir', 'share');
    my $seed = $system->child('sharedstatedir', 'seed');
    mode_is($config, 0640, 'fresh declared conffile mode');
    mode_is($public, 0644, 'undeclared conffile retains default');
    mode_is($explicit, 0640, 'mode applies to explicit non-sysconfdir conffile');
    mode_is($seed, 0644, 'undeclared state payload retains default');
    mode_is($system->child('docdir', 'doc'), 0444,
        'undeclared payload of other path types keeps installer mode');
    mode_is($system->child('srvdir', 'srv.file'), 0777, 'execute bits supported');

    chmod(0600, $config, $public) == 2 or die $!;
    ship_config("unedited upgrade\n");
    install_ok('');
    is($config->slurp, "unedited upgrade\n", 'upgrade replaces unedited conffile');
    mode_is($config, 0600, 'upgrade preserves stricter administrator mode');
    mode_is($public, 0644, 'undeclared upgrade keeps legacy chmod behavior');

    $config->spew("local edits\n");
    chmod(0600, $config) or die $!;
    ship_config("new shipped version\n");
    install_ok("N\n");
    my $alternate = path($config.'-spc');
    mode_is($config, 0600, 'kept conffile preserves stricter mode');
    mode_is($alternate, 0640, 'new -spc uses declared mode');
    chmod(0600, $alternate) or die $!;
    install_ok('');
    mode_is($alternate, 0600, 'repeated -spc install preserves stricter mode');
    is($config->slurp, "local edits\n", 'reinstall keeps local bytes');

    ship_config("accepted version\n");
    install_ok("Y\n");
    mode_is($config, 0600, 'replacement keeps pre-install restriction');
    mode_is(path($config.'-old'), 0600, 'backup preserves stricter mode');

    # With a looser old mode, tighten both the kept file and its new backup.
    path($config.'-old')->remove;
    $config->spew("more local edits\n");
    chmod(0644, $config) or die $!;
    ship_config("another accepted version\n");
    install_ok("Y\n");
    mode_is($config, 0640, 'declaration tightens looser existing mode');
    mode_is(path($config.'-old'), 0640, 'declaration also tightens backup');

    my $checksums = $system->child('sharedstatedir', 'syspath', 'install-checksums.json');
    my $checksums_before = $checksums->slurp;
    # A looser live mode would visibly change if staging touched the live file.
    chmod(0644, $config) or die $!;
    my $stage = $temporary->child('stage');
    install_ok('', '--destdir='.$stage);
    my $staged_config = path($stage, "$config");
    mode_is($staged_config, 0640, 'install-time destdir gets declared mode');
    mode_is($config, 0644, 'staging leaves live permissions intact');
    chmod(0600, $staged_config) or die $!;
    install_ok('', '--destdir='.$stage);
    mode_is($staged_config, 0600, 'staged reinstall preserves staged restriction');

    ship_config("version whose chmod fails\n");
    {
        local $ENV{SYSPATH_TEST_REMOVE_AFTER_COPY} = "$config";
        my ($status, $output) = run_build('', 'Build', 'install');
        isnt($status, 0, 'missing target makes final chmod fail');
        like($output, qr/cannot chmod '\Q$config\E' to 0640:/,
            'chmod failure reports destination and effective mode');
    }
    is($checksums->slurp, $checksums_before, 'chmod failure does not record checksums');
};

done_testing;
