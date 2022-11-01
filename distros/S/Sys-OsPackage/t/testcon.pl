#!/usr/bin/perl 
# testcon.pl - start unit test container
# by Ian Kluft
use strict;
use warnings;
use utf8;
use autodie;
use Carp qw(carp croak);
use Getopt::Long;
use Cwd;
use File::Copy::Recursive qw(rcopy_glob pathempty);

# test configuration
my $workspace = "t/container-workspace";
my %distro_subst = (
    "opensuse" => "opensuse/tumbleweed",
    "kalilinux" => "kalilinux/kali-last-release"
);
my @distros = qw(fedora rockylinux almalinux debian ubuntu alpine archlinux opensuse kalilinux);
my %special = (
    #"perl58" => {image => "perl", tag => "5.8.9-slim-buster"},
);
my @copyfiles = (
    qw(lib bin t/002_basic.t),
);

#
# main
#

# set timestamp for container environment
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
$mon++;
$year += 1900;
$ENV{CONTAINER_TEST_TIMESTAMP} = sprintf("%04d-%02d-%02d-%02d-%02d-%02d", $year, $mon, $mday, $hour, $min, $sec);

# process command line
my %args;
GetOptions(\%args, (@distros, keys %special));
my $total_distros = 0; # count to make sure exactly one was selected
my %image_spec = (tag => "latest");
foreach my $key (@distros) {
    if ((exists $args{$key}) ? $args{$key} : 0) {
        $total_distros++;
        my $image_name = (exists $distro_subst{$key}) ? $distro_subst{$key} : $key; 
        $image_spec{image} = $image_name;
    }
}
foreach my $special (keys %special) {
    if (exists $args{$special}) {
        $total_distros++;
        %image_spec = %{$special{$special}};
    }
}
if ($total_distros != 1) {
    croak "one distro must be selected, only one at a time (got $total_distros)";
}

# copy files to workspace directory
foreach my $fileglob (@copyfiles) {
    next if $fileglob eq "";
    if (-d "$workspace/$fileglob") {
        pathempty "$workspace/$fileglob";
    }
    rcopy_glob($fileglob, $workspace)
        or croak "failed to copy $fileglob";
}

# get a copy of Sys::OsRelease to solve chicken-and-egg problem on startup
my $orig_cwd = getcwd();
chdir $workspace;
system "cpan -g Sys::OsRelease >/dev/null 2>&1";

# find container command: Podman is Open Source and uses local containers
# Docker can possibly be added as a search option below, untested/unsupported but CLI options should be compatible
my $container_cmd;
DIR_LOOP: foreach my $pathdir (split /:/, $ENV{PATH}) {
    foreach my $cmdname (qw(podman)) {
        if (-x "$pathdir/$cmdname") {
            $container_cmd = "$pathdir/$cmdname";
            last DIR_LOOP;
        }
    }
}
if (not defined $container_cmd) {
    print qq{1..0 # SKIP container tests - podman not found in PATH\n};
    exit 0;
}

# launch container
exec $container_cmd, "run",
    "--mount=type=bind,source=$orig_cwd/$workspace,destination=/work,readonly=false,relabel=shared",
    "--env", "CONTAINER_TEST_*", "$image_spec{image}:$image_spec{tag}", "/work/startup"
    or croak "exec failed; $!";
