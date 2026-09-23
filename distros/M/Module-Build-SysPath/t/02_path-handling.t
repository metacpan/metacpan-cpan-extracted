#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture_merged';
use Cwd 'getcwd';
use File::Copy::Recursive 'dircopy';
use FindBin '$Bin';
use Path::Tiny 'path';
use Sys::Path;

my $source = path($Bin, 'tdirs', 'Acme-Test-SysPath')->absolute;
my $temporary = Path::Tiny->tempdir('syspath-paths-XXXXXXXX');
my $distribution = $temporary->child('release[1] (candidate)+.v1');
my $destination = $temporary->child('installed[1] (candidate)+.v1');

ok(dircopy($source, $distribution), 'copy distribution to metacharacter path');

my $visible = $distribution->child('www', 'Xhidden', 'visible');
$visible->parent->mkpath;
$visible->spew("visible sibling\n");

my $hidden = $distribution->child('www', '.private[1]+', 'hidden');
$hidden->parent->mkpath;
$hidden->spew("hidden payload\n");

my @inc = map { '-I'.path($_)->absolute } @INC;
my $run = sub {
    my (@args) = @_;
    my $original_directory = getcwd();
    my $status;
    my $output = capture_merged {
        chdir($distribution) or die $!;
        system($^X, @inc, @args);
        $status = $?;
        chdir($original_directory) or die $!;
    };
    is($status, 0, join(' ', @inc, @args).' succeeds') or diag($output);
    return $output;
};

$run->('Build.PL', '--destdir='.$destination);
$run->('Build');

ok($distribution->child('blib', 'webdir', 'www')->is_file,
    'ordinary source maps to the exact webdir build destination');
ok($distribution->child('blib', 'webdir', 'Xhidden', 'visible')->is_file,
    'visible sibling of hidden directory remains included');
ok(!$distribution->child('blib', 'webdir', '.hidden', 'hidden')->exists,
    'ordinary hidden-directory payload is excluded');
ok(!$distribution->child('blib', 'webdir', '.private[1]+', 'hidden')->exists,
    'metacharacter hidden-directory payload is excluded');

$run->('Build', 'install');

my $installed_webdir = $destination->child(
    path(Sys::Path->webdir)->absolute->relative(path('/')),
);
ok($installed_webdir->child('www')->is_file,
    'ordinary source installs at the exact system destination');
ok($installed_webdir->child('Xhidden', 'visible')->is_file,
    'visible sibling installs at the exact system destination');
ok(!$installed_webdir->child('.hidden', 'hidden')->exists,
    'ordinary hidden-directory payload is not installed');
ok(!$installed_webdir->child('.private[1]+', 'hidden')->exists,
    'metacharacter hidden-directory payload is not installed');

done_testing;
