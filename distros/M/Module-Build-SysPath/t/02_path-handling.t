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

$distribution->child('www', '.listed')->spew("listed dot file\n");
$distribution->child('www', 'forgotten')->spew("unlisted payload\n");
$distribution->child('www', 'www~')->spew("editor backup matching MANIFEST.SKIP\n");
$distribution->child('www', '.unwanted')->spew("unlisted dot file\n");
$distribution->child('log', 'acme-log', 'app.log')->spew("runtime log\n");
$distribution->child('log', 'acme-unlisted', '.exists')->touchpath;
$distribution->child('MANIFEST')->append("www/Xhidden/visible\nwww/.listed\n");
my $build_pl = $distribution->child('Build.PL');
$build_pl->edit(sub { s/(conffiles\s*=>)/webdir_files => { 'www\/.listed' => 1 },\n    $1/ });

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

my $configure_output = $run->('Build.PL', '--destdir='.$destination);
like($configure_output, qr{www/forgotten.*not listed in MANIFEST},
    'unlisted payload file is reported');
like($configure_output, qr{log/acme-unlisted/\.exists.*not listed in MANIFEST},
    'unlisted folder marker is reported');
unlike($configure_output, qr{(?:\.private|\.unwanted|app\.log|www~).*not listed in MANIFEST},
    'files excluded for other reasons or by MANIFEST.SKIP are not reported');
$run->('Build');

ok($distribution->child('blib', 'webdir', 'www')->is_file,
    'ordinary source maps to the exact webdir build destination');
ok($distribution->child('blib', 'webdir', 'Xhidden', 'visible')->is_file,
    'visible sibling of hidden directory remains included');
ok(!$distribution->child('blib', 'webdir', '.hidden', 'hidden')->exists,
    'ordinary hidden-directory payload is excluded');
ok(!$distribution->child('blib', 'webdir', '.private[1]+', 'hidden')->exists,
    'metacharacter hidden-directory payload is excluded');
ok($distribution->child('blib', 'webdir', '.listed')->is_file,
    'dot file listed in webdir_files is included');
ok(!$distribution->child('blib', 'webdir', 'forgotten')->exists,
    'payload file missing from MANIFEST is excluded');
ok(!$distribution->child('blib', 'webdir', 'www~')->exists,
    'file matching MANIFEST.SKIP is excluded');

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
ok(!$destination->child(
    path(Sys::Path->logdir)->absolute->relative(path('/')), 'acme-unlisted',
)->exists, 'folder marker missing from MANIFEST creates no folder');

done_testing;
