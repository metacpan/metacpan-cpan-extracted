#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use IPC::Open3 'open3';
use Symbol 'gensym';

use FindBin '$Bin';
use lib File::Spec->catdir($Bin, '..', 'lib');
use Sys::Path::SPc;

my $script = File::Spec->catfile($Bin, '..', 'script', 'syspath.pl');
my @path_types = Sys::Path::SPc->_path_types;

my ($status, $stdout, $stderr) = run_script();
is($status, 0, 'all-path output succeeds');
is(
    $stdout,
    join('', map { $_."\t".Sys::Path::SPc->$_."\n" } @path_types),
    'no arguments print every configured path in canonical order',
);
is($stderr, '', 'all-path output has no diagnostics');

($status, $stdout, $stderr) = run_script('srvdir', 'prefix');
is($status, 0, 'selected-path output succeeds');
is(
    $stdout,
    'srvdir'."\t".Sys::Path::SPc->srvdir."\n"
        .'prefix'."\t".Sys::Path::SPc->prefix."\n",
    'arguments select paths and preserve command-line order',
);
is($stderr, '', 'selected-path output has no diagnostics');

($status, $stdout, $stderr) = run_script('--help');
is($status, 0, '--help succeeds');
like($stdout, qr/^Name:\n/m, 'help includes NAME');
like($stdout, qr/^Usage:\n/m, 'help includes SYNOPSIS');
like($stdout, qr/^Description:\n/m, 'help includes DESCRIPTION');
for my $path_type (@path_types) {
    like($stdout, qr/^\s+\Q$path_type\E\s*$/m, "help lists $path_type");
}
is($stderr, '', '--help has no diagnostics');

($status, $stdout, $stderr) = run_script('prefix', 'not-a-path');
isnt($status, 0, 'an unknown path fails');
is($stdout, '', 'an unknown path prevents partial output');
like(
    $stderr,
    qr/Unknown path key "not-a-path"/,
    'the usage error identifies the unknown key',
);

done_testing();

sub run_script {
    my (@args) = @_;
    my $error_fh = gensym();
    my $pid = open3(
        my $input_fh,
        my $output_fh,
        $error_fh,
        $^X,
        '-I'.File::Spec->catdir($Bin, '..', 'lib'),
        $script,
        @args,
    );
    close $input_fh;
    my $output = do { local $/; <$output_fh> } // '';
    my $error = do { local $/; <$error_fh> } // '';
    waitpid($pid, 0);
    return ($? >> 8, $output, $error);
}
