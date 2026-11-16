#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Copy::Recursive 'dircopy';
use File::Temp;
use FindBin '$Bin';
use Path::Tiny 'path';
use POSIX ();

my $temporary = Path::Tiny->tempdir('syspath-owners-XXXXXXXX');

# A non-root user can only chgrp to its own groups, so the test needs one
# supplementary group besides the group that new files get.
my $default_gid = (stat($temporary))[5];
my ($group) = grep { $_ != $default_gid } split(' ', $));
plan skip_all => 'needs membership in a second group'
    if not defined $group;

my $dist = $temporary->child('distribution');
my $system = $temporary->child('system');
ok(dircopy(path($Bin, 'tdirs', 'Acme-Test-SysPath'), $dist), 'copy distribution');

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

sub install_ok {
    my ($answer, @args) = @_;
    my ($status, $output) = run_build($answer, 'Build', 'install', @args);
    is($status, 0, 'install succeeds') or diag $output;
    return $output;
}

sub ship {
    my ($blib_type, $file, $content) = @_;
    $dist->child(split(m{/}, $file))->spew($content);
    # Module::Build compares mtimes; same-second edits must rebuild too.
    my $built = $dist->child('blib', $blib_type, path($file)->basename);
    $built->remove if $built->exists;
}

sub group_is {
    my ($file, $gid, $description) = @_;
    my @stat = stat($file);
    is(@stat ? $stat[5] : undef, $gid, $description);
}

# Edit in place like an administrator; Path::Tiny's spew would replace the
# file and drop its group.
sub edit {
    my ($file, $content) = @_;
    open(my $fh, '>', $file) or die "$file: $!";
    print {$fh} $content;
    close($fh) or die "$file: $!";
}

sub set_group {
    my (@files) = @_;
    chown(-1, $group, @files) == @files or die "chgrp $group: $!";
}

my $build = $dist->child('Build.PL')->slurp;
$build =~ s/(module_name\s*=>)/file_modes => { 'conf\/acme-test-syspath.cfg' => 0640 },\n    $1/;
$dist->child('Build.PL')->spew($build);
my ($status, $output) = run_build('', 'Build.PL', '--install_base='.$system.'/perl');
is($status, 0, 'configure') or diag $output;
install_ok('');

my $config = $system->child('sysconfdir', 'acme-test-syspath.cfg');
my $data = $system->child('datadir', 'share');
my $doc = $system->child('docdir', 'doc');
group_is($config, $default_gid, 'fresh install uses the installer group');

subtest 'replaced unedited files keep owner and group' => sub {
    set_group($config, $data, $doc);
    ship('sysconfdir', 'conf/acme-test-syspath.cfg', "unedited upgrade\n");
    ship('docdir', 'doc/doc', "new doc\n");
    install_ok('');
    is($config->slurp, "unedited upgrade\n", 'unedited conffile replaced');
    is($doc->slurp, "new doc\n", 'other payload replaced');
    group_is($config, $group, 'replaced conffile keeps group');
    group_is($doc, $group, 'replaced payload keeps group');
    group_is($data, $group, 'unchanged payload keeps group');
};

subtest 'kept conffile and its -spc copy keep owner and group' => sub {
    edit($config, "local edits\n");
    ship('sysconfdir', 'conf/acme-test-syspath.cfg', "new shipped version\n");
    install_ok("N\n");
    my $alternate = path($config.'-spc');
    is($config->slurp, "local edits\n", 'local edits kept');
    group_is($config, $group, 'kept conffile keeps group');
    group_is($alternate, $default_gid, 'new -spc uses the installer group');

    set_group($alternate);
    ship('sysconfdir', 'conf/acme-test-syspath.cfg', "newer shipped version\n");
    install_ok("N\n");
    is($alternate->slurp, "newer shipped version\n", '-spc replaced');
    group_is($alternate, $group, 'replaced -spc keeps group');
};

subtest 'accepted new version inherits owner and group' => sub {
    ship('sysconfdir', 'conf/acme-test-syspath.cfg', "accepted version\n");
    install_ok("Y\n");
    is($config->slurp, "accepted version\n", 'new version installed');
    group_is($config, $group, 'new conffile gets group of replaced one');
    group_is(path($config.'-old'), $group, 'backup keeps group');
};

subtest '--destdir keeps owner and group of staged files' => sub {
    my $stage = $temporary->child('stage');
    install_ok('', '--destdir='.$stage);
    my $staged = path($stage, "$config");
    group_is($staged, $default_gid, 'fresh staged file uses the installer group');
    set_group($staged);
    ship('sysconfdir', 'conf/acme-test-syspath.cfg', "staged upgrade\n");
    install_ok('', '--destdir='.$stage);
    is($staged->slurp, "staged upgrade\n", 'staged file replaced');
    group_is($staged, $group, 'replaced staged file keeps group');
    group_is($config, $group, 'live file untouched');
};

done_testing;
