#!perl
# $Id$
use strict;
use File::Spec;

my $interactive = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
my($version, $cflags, $libs, $tmp);

=head1
print 
    "******************************\n",
    "* WARNING! WARNING! WARNING! *\n",
    "******************************\n",
    "\n",
    "This version of Senna.pm breaks compatibility with the previous versions.\n",
    "You are STRONGLY advised to audit your applications prior to upgrading.\n",
    "\n",
    "Proceed ? [n] ";

$tmp = <STDIN>;
chomp $tmp;
if ($tmp !~ /^y(?:es)?$/) {
    exit 1;
}
=cut

print "Probing for libsenna ...\n";

my $senna_cfg;
my @path = (split(/:/, $ENV{PATH}), qw(/usr/local/bin /usr/bin /opt/bin /bin));
foreach my $path (@path) {
    my $fqpath = File::Spec->catfile($path, 'senna-cfg');
    if (-x $fqpath) {
        $senna_cfg = $fqpath;
        last;
    }
}

print "Path to senna-cfg? [$senna_cfg] ";

if ($interactive) {
    $tmp = <STDIN>;
    chomp $tmp;
    if ($tmp) {
        $senna_cfg = $tmp;
    }
}

if (!-f $senna_cfg || ! -x _) {
    print <<"EOM";
We were unable to find senna-cfg. This script uses mecab-config to auto-probe 
  1. The version string of libsenna that you are building Senna
     against. (e.g. 0.8.0)
  2. Additional compiler flags that you may have built libsenna with, and
  3. Additional linker flags that you may have build libsenna with.

Since we can't auto-probe, you should specify the above three to proceed
with compilation:
EOM
}

$version = `$senna_cfg --version`;
chomp($version);

print "libsenna version? [$version] ";
if ($interactive) {
    $tmp = <STDIN>;
    chomp($tmp);
    if ($tmp) {
        $version = $tmp;
    }
}

if (! $version) {
    print STDERR "No version specified. Cowardly refusing to proceed\n";
    exit 1;
}

# As of Senna 0.20, we only work with libsenna > 0.8.0
my ($major, $minor, $micro) = split(/\./, $version);

# I don't know if this is viable in every case, but I think using the
# old perl notation $major + $minor / 1000 + $micro / 1000000 is safe
# for a sane comparison
my $fractional_version = $major + $minor / 1000 + $micro / 1_000_000;
if ($fractional_version <  0.008) {
    print STDERR "This module requires senna 0.8.0 or above. You have $version\n";
    exit 1;
}


$cflags = `$senna_cfg --cflags`;
chomp($cflags);
print "additional compiler flags? [$cflags] ";
if ($interactive) {
    $tmp = <STDIN>;
    chomp ($tmp);
    if ($tmp) {
        $cflags = $tmp;
    }
}

$libs = `$senna_cfg --libs`;
chomp($libs);
$libs = join(" ", $libs, "-lsenna");

print "additional linker flags? [$libs] ";
if ($interactive) {
    $tmp = <STDIN>;
    chomp ($tmp);
    if ($tmp) {
        $libs = $tmp;
    }
}

my %ret = (
    version => $version,
    cflags  => $cflags,
    libs    => $libs
);

return \%ret;
