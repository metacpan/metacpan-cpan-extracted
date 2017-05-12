#!/usr/bin/perl -w
use strict;

# This is really just a wrapper around
# make all test manifest dist
#
# But it does a few pre-flight checks too

use File::Path;
use File::Copy;
use Config;
my $perlpath = $Config{perlpath};

use lib 'lib';
use Parallel::Loops;

# Check that Changes and $Parallel::Loops::VERSION  agree on what the latest
# version is
open I, 'Changes'
    or die "Couldn't open Changes";
my $version = <I>;
close I;
chomp $version;
$version =~ /^Version (.*) on /
    or die "Unexpected version line: $version";
$version = $1;

# Test that this version number is the same as that in the .pm
die sprintf ("Version mismatch: Changes: '%s', pm: '%s'",
             $version, $Parallel::Loops::VERSION)
    if ($version ne $Parallel::Loops::VERSION);

my $tarballFile = "Parallel-Loops-$version.tar.gz";
my $tarballDir = "tarball";
if (-e $tarballFile) {
    die "$tarballFile already exists - remove it first"
}
if (-d $tarballDir) {
    die "$tarballDir dir already exists - remove it first"
}
sub safeSystem {
    system(@_);
    die sprintf( "system call '%s' failed: %d",
                 join(" ", @_),
                 $?
               )
        if $?;
}
# Make sure we have an updated README
safeSystem('pod2text --utf8 lib/Parallel/Loops.pm > README');
safeSystem('pod2markdown lib/Parallel/Loops.pm > README.md');

# Just want to make sure we die if anything isn't up-to-date
safeSystem('git diff --exit-code > /dev/null');
safeSystem('git archive HEAD --prefix=tarball/ | tar x');
chdir "tarball";

safeSystem($perlpath, 'Makefile.PL');
safeSystem('make', 'all', 'test','manifest', 'dist');
move("$tarballFile", '..');
chdir "..";
rmtree("tarball");
