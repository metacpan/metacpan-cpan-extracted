#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;
use Test::Dirs 0.03;

use Capture::Tiny 'capture_merged';
use Cwd 'getcwd';
use File::Copy::Recursive 'dircopy';
use File::Find::Rule;
use Path::Tiny 'path';
use File::Temp;

use FindBin qw($Bin);
use lib File::Spec->catfile($Bin, 'lib');
use lib File::Spec->catfile($Bin, '..', 'lib');

BEGIN {
    use_ok ( 'Module::Build::SysPath' ) or exit;
}

exit main();

sub main {
    my $src1      = File::Spec->catdir($Bin, 'tdirs', 'Acme-Test-SysPath');
    my $src1_inst = File::Spec->catdir($Bin, 'tdirs', 'Acme-Test-SysPath.installed');
    subtest 'distribution installs system paths and payload files' => sub {
        my $tmp_root = File::Temp->newdir();
        my $tmp_dir = File::Spec->catdir($tmp_root, 'copied distribution');
        ok(dircopy($src1, $tmp_dir), 'copy Acme::Test::SysPath to tmp folder');
        my $dest_dir = File::Temp->newdir(
            'installed distribution XXXXXXXX', TMPDIR => 1,
        );

        # Work around empty folders omitted from fresh checkouts and distdirs.
        if (not -e File::Spec->catdir($src1_inst, 'var', 'cache', 'acme-cache')) {
            diag('creating missing empty folders');
            foreach my $folder_type (qw(cache lock log run spool)) {
                my $empty_folder = path(
                    $src1_inst, 'var', $folder_type, 'acme-'.$folder_type,
                );
                diag($empty_folder->child($empty_folder));
                $empty_folder->mkdir;
            }
            path($src1_inst, 'var', 'lib', 'acme-state')->mkdir;
            path($src1_inst, 'var', 'www', 'empty')->mkdir;
        }

        my @inc = map { '-I'.$_ } @INC;
        my $run = sub {
            my (@args) = @_;
            my $original_directory = getcwd();
            my $status;
            my $output = capture_merged {
                chdir($tmp_dir) or die $!;
                system($^X, @args);
                $status = $?;
                chdir($original_directory) or die $!;
            };
            is($status, 0, join(' ', @args).' succeeds') or diag($output);
            return $output;
        };

        my $build_out = $run->(@inc, 'Build.PL', '--destdir='.$dest_dir);
        like($build_out, qr/Acme-Test-SysPath/, 'Build.PL output');

        my @injection = $ENV{SYSPATH_TEST_FAIL_ORIGINAL_INSTALL}
            ? ('-I'.File::Spec->catdir($Bin, 'lib'), '-MPostCopyFailure')
            : ();
        $run->(@injection, 'Build', 'install');

        my ($packlist) = File::Find::Rule->file->name('.packlist')->in($dest_dir);
        dir_cleanup_ok($packlist, 'cleanup auto/');

        SKIP: {
            my ($man_folder) = File::Find::Rule->directory->name('man')->in($dest_dir);
            skip('no man on this os') if not $man_folder;
            dir_cleanup_ok($man_folder, 'cleanup man');
        }

        my ($installed_spc) = File::Find::Rule->file->name('SPc.pm')->in($dest_dir);
        ok($installed_spc, 'installed SPc module exists');
        my $loaded;
        $loaded = do $installed_spc if $installed_spc;
        ok($loaded, 'installed SPc module loads') or diag($@ || $!);
        if ($loaded) {
            foreach my $path_type (Acme::Test::SysPath::SPc->_path_types) {
                is(
                    Acme::Test::SysPath::SPc->$path_type,
                    Sys::Path->$path_type,
                    "$path_type accessor uses the system path",
                );
            }
        }
        my ($pm_folder) = File::Find::Rule->file->name('SysPath.pm')->in($dest_dir);
        dir_cleanup_ok($pm_folder, 'cleanup SysPath.pm');

        is_dir($dest_dir, $src1_inst, 'Acme::Test::SysPath install folders');
        done_testing();
    };

    subtest 'configuration decisions use install-time contents' => sub {
        local $ENV{PERL_MM_USE_DEFAULT} = 1;
        my $dist = temp_copy_ok($src1, 'copy configuration test distribution');
        my $system = File::Temp->newdir();
        path($system, 'sharedstatedir', 'syspath')->mkdir;
        local $ENV{SYSPATH_TEST_ROOT} = "$system";
        IO::Any->spew([''.$dist, 'TestPaths.pm'], <<'PERL');
use Sys::Path::SPc;
use File::Spec;
use Monkey::Patch::Action qw(patch_package);
no warnings 'redefine';
for my $type (Sys::Path::SPc->_path_types) {
    no strict 'refs';
    *{"Sys::Path::SPc::$type"} = sub {
        File::Spec->catdir($ENV{SYSPATH_TEST_ROOT}, $type);
    };
}
if ($ENV{SYSPATH_TEST_FAIL_INSTALL}) {
    require Module::Build;
    no warnings 'redefine';
    *Module::Build::ACTION_install = sub {
        die "injected parent install failure\n";
    };
}
require Module::Build::SysPath;
our @SPC_PATCHES;
for my $operation (qw(open_source write close rename)) {
    push @SPC_PATCHES, patch_package(
        'Module::Build::SysPath', '_spc_'.$operation, 'wrap', sub {
            my $context = shift;
            my $failure = $operation eq 'open_source' ? 'open' : $operation;
            if (($ENV{SYSPATH_TEST_FAIL_SPC} || '') eq $failure) {
                $context->{'orig'}->(@_)
                    if $failure eq 'close' and $_[2] eq 'destination';
                die "injected SPc $failure failure\n";
            }
            return $context->{'orig'}->(@_);
        },
    );
}
1;
PERL
        my @inc = map { '-I'.$_ } @INC;
        my $run = sub {
            my ($input, @args) = @_;
            # Read scripted answers even when the outer installer uses defaults.
            local $ENV{PERL_MM_USE_DEFAULT} = 0;
            my $stdin = File::Temp->new();
            print {$stdin} $input;
            seek($stdin, 0, 0) or die $!;
            my $pid = open(my $out, '-|');
            die $! unless defined $pid;
            if (!$pid) {
                chdir $dist or die $!;
                open(STDIN, '<&', $stdin) or die $!;
                open(STDERR, '>&', STDOUT) or die $!;
                exec $^X, @inc, '-I'.$dist, '-MTestPaths', @args;
                die "exec: $!";
            }
            local $/;
            my $output = <$out>;
            close $out;
            if ($ENV{SYSPATH_TEST_FAIL_INSTALL} or $ENV{SYSPATH_TEST_EXPECT_FAILURE}) {
                isnt($?, 0, "@args failed as requested") or diag $output;
            }
            else {
                is($?, 0, "@args succeeded") or diag $output;
            }
            return $output;
        };
        my $source = File::Spec->catfile($dist, 'conf', 'acme-test-syspath.cfg');
        my $config = File::Spec->catfile($system, 'sysconfdir', 'acme-test-syspath.cfg');
        my $explicit_source = File::Spec->catfile($dist, 'share', 'share');
        my $explicit_config = File::Spec->catfile($system, 'datadir', 'share');
        my $original = IO::Any->slurp([$source]);
        my $explicit_original = IO::Any->slurp([$explicit_source]);
        $run->('', 'Build.PL', '--install_base='.$system.'/perl');
        $run->('', 'Build', 'install');
        is(IO::Any->slurp([$config]), $original,
            'initial implicit sysconfdir configuration installed');
        is(IO::Any->slurp([$explicit_config]), $explicit_original,
            'initial explicit non-sysconfdir configuration installed');
        my $checksums = JSON::Util->decode([
            "$system", 'sharedstatedir', 'syspath', 'install-checksums.json',
        ]);
        is($checksums->{$config}, Digest::MD5::md5_hex($original),
            'implicit sysconfdir configuration checksum recorded');
        is($checksums->{$explicit_config}, Digest::MD5::md5_hex($explicit_original),
            'explicit non-sysconfdir configuration checksum recorded');

        $run->('', 'Build.PL', '--install_base='.$system.'/perl');
        IO::Any->spew([$config], "local changes after Build.PL\n");
        chmod 0644, $explicit_config or die $!;
        IO::Any->spew([$explicit_config], "local explicit changes after Build.PL\n");
        my $output = $run->('', 'Build', 'install');
        is(IO::Any->slurp([$config]), "local changes after Build.PL\n",
            'local changes to implicit configuration survive install');
        ok(-f $config.'-spc', 'implicit distribution configuration installed as -spc');
        is(IO::Any->slurp([$config.'-spc']), $original, '-spc contains distribution bytes')
            if -f $config.'-spc';
        is(IO::Any->slurp([$explicit_config]), "local explicit changes after Build.PL\n",
            'local changes to explicit non-sysconfdir configuration survive install');
        ok(-f $explicit_config.'-spc',
            'explicit non-sysconfdir distribution configuration installed as -spc');
        is(IO::Any->slurp([$explicit_config.'-spc']), $explicit_original,
            'explicit non-sysconfdir -spc contains distribution bytes')
            if -f $explicit_config.'-spc';
        unlike($output, qr/What would you like to do/, 'unchanged distribution does not prompt');

        $run->('', 'Build', 'install');
        is(IO::Any->slurp([$config]), "local changes after Build.PL\n",
            'repeated install with reused blib preserves local changes');
        my $built = File::Spec->catfile($dist, 'blib', 'sysconfdir', 'acme-test-syspath.cfg');
        ok(-f $built && !-e $built.'-spc', 'ordinary build filename restored');

        for my $answer (qw(N Y)) {
            $output = $run->('', 'Build.PL', '--install_base='.$system.'/perl');
            unlike($output, qr/What would you like to do/, 'Build.PL does not prompt');
            my $version = "distribution version for $answer\n";
            IO::Any->spew([$source], $version);
            unlink($built) or die $!;
            $output = $run->("$answer\n", 'Build', 'install');
            like($output, qr/What would you like to do/, 'changed distribution prompts at install');
            is(IO::Any->slurp([$config]),
                $answer eq 'Y' ? $version : "local changes after Build.PL\n",
                "$answer applies the selected configuration policy");
            is(IO::Any->slurp([$config.($answer eq 'Y' ? '-old' : '-spc')]),
                $answer eq 'Y' ? "local changes after Build.PL\n" : $version,
                "$answer retains the other configuration version");
            my $checksums = JSON::Util->decode([
                "$system", 'sharedstatedir', 'syspath', 'install-checksums.json',
            ]);
            is($checksums->{$config}, Digest::MD5::md5_hex($version),
                'checksum reflects source changed after Build.PL');
        }

        unlink($config.'-old') or die $!;
        my $local_before_failure = "local configuration before failed install\n";
        my $failed_version = "distribution version for failed install\n";
        IO::Any->spew([$config], $local_before_failure);
        IO::Any->spew([$source], $failed_version);
        unlink($built) or die $!;
        {
            local $ENV{SYSPATH_TEST_FAIL_INSTALL} = 1;
            $output = $run->("Y\n", 'Build', 'install');
        }
        like($output, qr/injected parent install failure/,
            'parent install failure is reported');
        is(-f $config ? IO::Any->slurp([$config]) : undef, $local_before_failure,
            'failed parent install restores active configuration');
        ok(!-e $config.'-old', 'rollback consumes temporary configuration backup');

        my $existing_backup = "pre-existing configuration backup\n";
        IO::Any->spew([$config.'-old'], $existing_backup);
        {
            local $ENV{SYSPATH_TEST_EXPECT_FAILURE} = 1;
            $output = $run->("Y\n", 'Build', 'install');
        }
        like($output, qr/configuration backup .* already exists/,
            'pre-existing configuration backup is reported');
        is(IO::Any->slurp([$config]), $local_before_failure,
            'backup collision leaves active configuration untouched');
        is(IO::Any->slurp([$config.'-old']), $existing_backup,
            'backup collision leaves existing backup untouched');

        unlink($config) or die $! if -e $config;
        $run->('', 'Build.PL', '--install_base='.$system.'/perl');
        IO::Any->spew([$config], "created after Build.PL\n");
        $run->('', 'Build', 'install');
        is(IO::Any->slurp([$config]), "created after Build.PL\n",
            'configuration created after Build.PL is protected');

        my $stage = File::Temp->newdir();
        my $checksum_file = File::Spec->catfile($system, 'sharedstatedir', 'syspath', 'install-checksums.json');
        my $checksums_before = IO::Any->slurp([$checksum_file]);
        $output = $run->('', 'Build', 'install', '--destdir='.$stage);
        unlike($output, qr/What would you like to do/, 'staged install does not prompt');
        is(IO::Any->slurp([File::Spec->catfile($stage, $config)]),
            IO::Any->slurp([$source]), 'install-time destdir gets ordinary distribution configuration');
        ok(!-e File::Spec->catfile($stage, $config.'-spc'), 'staged install has no -spc copy');
        is(IO::Any->slurp([$config]), "created after Build.PL\n", 'staging leaves live configuration intact');
        is(IO::Any->slurp([$checksum_file]), $checksums_before, 'staging leaves live checksums intact');

        my $source_spc = File::Spec->catfile(
            $dist, 'lib', 'Acme', 'Test', 'SysPath', 'SPc.pm',
        );
        my ($installed_spc) = File::Find::Rule->file->name('SPc.pm')->in(
            File::Spec->catdir($system, 'perl'),
        );
        for my $failure (qw(open write close rename)) {
            my $new_version = "configuration before SPc $failure failure\n";
            IO::Any->spew([$source], $new_version);
            unlink($built) or die $! if -e $built;
            {
                local $ENV{SYSPATH_TEST_EXPECT_FAILURE} = 1;
                local $ENV{SYSPATH_TEST_FAIL_SPC} = $failure;
                $output = $run->("N\n", 'Build', 'install');
            }
            like($output, qr/injected SPc $failure failure/,
                "$failure failure is reported");
            is(IO::Any->slurp([$installed_spc]), IO::Any->slurp([$source_spc]),
                "$failure failure preserves the installed SPc module");
            is(IO::Any->slurp([$checksum_file]), $checksums_before,
                "$failure failure does not commit checksums");
        }

        $run->("N\n", 'Build', 'install');
        isnt(IO::Any->slurp([$installed_spc]), IO::Any->slurp([$source_spc]),
            'successful install transforms the SPc module');
        is((stat($installed_spc))[2] & oct('7777'), oct('444'),
            'transformed SPc module retains installed permissions');
    };

    return 0;
}
