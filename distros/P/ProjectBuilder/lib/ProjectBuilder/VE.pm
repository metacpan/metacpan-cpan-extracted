#!/usr/bin/perl -w
#
# Common functions for virtual environment
# 
# Copyright B. Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2
#
# $Id$
#

package ProjectBuilder::VE;

use strict;
use Data::Dumper;
use Carp 'confess';
use English;
use File::Basename;
use ProjectBuilder::Version;
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use ProjectBuilder::Distribution;

# Global vars
# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our @ISA = qw(Exporter);
our @EXPORT = qw(pb_ve_launch pb_ve_snap pb_ve_get_type pb_ve_docker_repo pb_ve_docker_get_image);

($VERSION,$REVISION) = pb_version_init();

=pod

=head1 NAME

ProjectBuilder::VE, part of the project-builder.org - module dealing with Virtual Environment

=head1 DESCRIPTION

This modules provides functions to deal with Virtual Environements (VE), aka chroot/containers.

=head1 SYNOPSIS

  use ProjectBuilder::VE;

  # 
  # Return information on the running distro
  #
  my $pbos = pb_ve_launch();

=head1 USAGE

=over 4

=item B<pb_ve_launch>

This function launches a VE, creating it if necessary using multiple external potential tools.

=cut

sub pb_ve_launch {

my $v = shift;
my $pbforce = shift;			# Which step are we in (0: create, 1: setup, 2: build, 3: use)
my $locsnap = shift;
my $vetype = shift;
my $pbimage = shift;

my $docrepo = "";			# By default no repository for docker available

pb_log(2,"Entering pb_ve_launch at step $pbforce for type $vetype\n");
# Get distro context
my $pbos = pb_distro_get_context($v);

$vetype = pb_ve_get_type($vetype);
my ($vepath) = pb_conf_get("vepath");

if ($vetype eq "docker") {
	$docrepo = pb_ve_docker_repo();
}

# Architecture consistency
my $arch = pb_get_arch();
if ($arch ne $pbos->{'arch'}) {
	die "Unable to launch a VE of architecture $pbos->{'arch'} on a $arch platform" unless (($pbos->{'arch'} =~ /i?86/o) && ($arch eq "x86_64"));
}

# If we are already root (from pbmkbm e.g.) don't use sudo, just call the command
my $sudocmd="";
if ($EFFECTIVE_USER_ID != 0) {
	$sudocmd ="sudo ";
	foreach my $proxy (qw/http_proxy ftp_proxy/) {
		if (defined $ENV{$proxy}) {
			open(CMD,"sudo sh -c 'echo \$$proxy' |") or die "can't run sudo sh?: $!";
			$_ = <CMD>;
			chomp();
			die "sudo not passing through env var $proxy; '$ENV{$proxy}' != '$_'\nAdd line Defaults:`whoami` env_keep += \"$proxy\" to sudoers file?" unless $_ eq $ENV{$proxy};
			close(CMD);
		}
	}
}

# Handle cross arch on Intel based platforms
$sudocmd = "setarch i386 $sudocmd" if (($pbos->{'arch'} =~ /i[3456]86/) && ($arch eq 'x86_64'));

my $root = pb_path_expand($vepath->{$ENV{PBPROJ}});
	
if (($vetype eq "chroot") || ($vetype eq "schroot") || ($vetype eq "docker")) {

	# We need to avoid umask propagation to the VE
	umask 0022;

	# We can probably only get those params now we have the distro context
	my ($rbsb4pi,$rbspi,$vesnap,$oscodename,$osmindep,$verebuild,$rbsmirrorsrv) = pb_conf_get_if("rbsb4pi","rbspi","vesnap","oscodename","osmindep","verebuild","rbsmirrorsrv");

	if (((((defined $verebuild) && ($verebuild->{$ENV{'PBPROJ'}} =~ /true/i)) || ($pbforce == 0)) && ($vetype ne "docker"))
		# For docker we may have a reference image that we'll use
		|| (($vetype eq "docker") && ($pbforce == 0) && ((not defined $pbimage) || ($pbimage eq "")))) {

		my ($verpmtype,$vedebtype) = pb_conf_get("verpmtype","vedebtype");
		my ($rbsopt1) = pb_conf_get_if("rbsopt");

		# We have to rebuild the chroot
		if ($pbos->{'type'} eq "rpm") {
	
			# Which tool is used
			my $verpmstyle = $verpmtype->{$ENV{'PBPROJ'}};
			die "No verpmtype defined for $ENV{PBPROJ}" unless (defined $verpmstyle);
	
			# Get potential rbs option
			my $rbsopt = "";
			if (defined $rbsopt1) {
				if (defined $rbsopt1->{$verpmstyle}) {
					$rbsopt = $rbsopt1->{$verpmstyle};
				} elsif (defined $rbsopt1->{$ENV{'PBPROJ'}}) {
					$rbsopt = $rbsopt1->{$ENV{'PBPROJ'}};
				} else {
					$rbsopt = "";
				}
			}
	
			my $postinstall = pb_ve_get_postinstall($pbos,$rbspi,$verpmstyle);
			if ($verpmstyle eq "rinse") {
				# Need to reshape the mirrors generated with local before-post-install script
				my $b4post = "--before-post-install ";
				my $postparam = pb_distro_get_param($pbos,$rbsb4pi);
				if ($postparam eq "") {
					$b4post = "";
				} else {
					$b4post .= $postparam;
				}
	
				# Need to reshape the package list for pb
				my $addpkgs;
				$postparam = "";
				$postparam .= pb_distro_get_param($pbos,$osmindep);
				if ($postparam eq "") {
					$addpkgs = "";
				} else {
					my $pkgfile = "$ENV{'PBTMP'}/addpkgs.lis";
					open(PKG,"> $pkgfile") || die "Unable to create $pkgfile";
					foreach my $p (split(/,/,$postparam)) {
						print PKG "$p\n";
					}
					close(PKG);
					$addpkgs = "--add-pkg-list $pkgfile";
				}
	
				my $rinseverb = "";
				$rinseverb = "--verbose" if ($pbdebug gt 0);
				my ($rbsconf) = pb_conf_get("rbsconf");
	
				my $command = pb_check_req("rinse",0);
				pb_system("$sudocmd $command --directory \"$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}\" --arch \"$pbos->{'arch'}\" --distribution \"$pbos->{'name'}-$pbos->{'version'}\" --config \"$rbsconf->{$ENV{'PBPROJ'}}\" $b4post $postinstall $rbsopt $addpkgs $rinseverb","Creating the rinse VE for $pbos->{'name'}-$pbos->{'version'} ($pbos->{'arch'})", "verbose");
			} elsif ($verpmstyle eq "rpmbootstrap") {
				my $rbsverb = "";
				foreach my $i (1..$pbdebug) {
					$rbsverb .= " -v";
				}
				my $addpkgs = "";
				my $postparam = "";
				$postparam .= pb_distro_get_param($pbos,$osmindep);
				if ($postparam eq "") {
					$addpkgs = "";
				} else {
					$addpkgs = "-a $postparam";
				}
				my $command = pb_check_req("rpmbootstrap",0);
				pb_system("$sudocmd $command $rbsopt $postinstall $addpkgs $pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'} $rbsverb","Creating the rpmbootstrap VE for $pbos->{'name'}-$pbos->{'version'} ($pbos->{'arch'})", "verbose");
				pb_system("$sudocmd /bin/umount $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}/proc","Umounting stale /proc","mayfail") if (-f "$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}/proc/cpuinfo");
			} elsif ($verpmstyle eq "mock") {
				my ($rbsconf) = pb_conf_get("rbsconf");
				my $command = pb_check_req("mock",0);
				pb_system("$sudocmd $command --init --resultdir=\"/tmp\" --configdir=\"$rbsconf->{$ENV{'PBPROJ'}}\" -r $v $rbsopt","Creating the mock VE for $pbos->{'name'}-$pbos->{'version'} ($pbos->{'arch'})");
				# Once setup we need to install some packages, the pb account, ...
				pb_system("$sudocmd $command --install --configdir=\"$rbsconf->{$ENV{'PBPROJ'}}\" -r $v su","Configuring the mock VE");
			} else {
				die "Unknown verpmtype type $verpmstyle. Report to dev team";
			}
		} elsif ($pbos->{'type'} eq "deb") {
			my $vedebstyle = $vedebtype->{$ENV{'PBPROJ'}};
		
			my $codename = pb_distro_get_param($pbos,$oscodename);
			my $postparam = "";
			my $addpkgs;
			$postparam .= pb_distro_get_param($pbos,$osmindep);
			if ($postparam eq "") {
				$addpkgs = "";
			} else {
				$addpkgs = "--include $postparam";
			}
			my $debmir = "";
			$debmir .= pb_distro_get_param($pbos,$rbsmirrorsrv);
	
			# Get potential rbs option
			my $rbsopt = "";
			if (defined $rbsopt1) {
				if (defined $rbsopt1->{$vedebstyle}) {
					$rbsopt = $rbsopt1->{$vedebstyle};
				} elsif (defined $rbsopt1->{$ENV{'PBPROJ'}}) {
					$rbsopt = $rbsopt1->{$ENV{'PBPROJ'}};
				} else {
					$rbsopt = "";
				}
			}
	
			# debootstrap works with amd64 not x86_64
			my $debarch = $pbos->{'arch'};
			$debarch = "amd64" if ($pbos->{'arch'} eq "x86_64");
			if ($vedebstyle eq "debootstrap") {
				my $dbsverb = "";
				$dbsverb = "--verbose" if ($pbdebug gt 0);
		
				# Some perl modules are in Universe on Ubuntu
				$rbsopt .= " --components=main,universe" if ($pbos->{'name'} eq "ubuntu");
		
				my $cmd1 = pb_check_req("mkdir",0);
				my $cmd2 = pb_check_req("debootstrap",0);
				pb_system("$sudocmd $cmd1 -p $root/$pbos->{name}/$pbos->{version}/$pbos->{arch} ; $sudocmd $cmd2 $dbsverb $rbsopt --arch=$debarch $addpkgs $codename \"$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}\" $debmir","Creating the debootstrap VE for $pbos->{'name'}-$pbos->{'version'} ($pbos->{'arch'})", "verbose");
				# debootstrap doesn't create an /etc/hosts file
				if (! -f "$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}/etc/hosts" ) {
					my $cmd = pb_check_req("cp",0);
					pb_system("$sudocmd $cmd /etc/hosts $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}/etc/hosts");
				}
			} else {
				die "Unknown vedebtype type $vedebstyle. Report to dev team";
			}
		} elsif ($pbos->{'type'} eq "ebuild") {
			die "Please teach the dev team how to build gentoo chroot";
		} else {
			die "Unknown distribution type $pbos->{'type'}. Report to dev team";
		}
	}

	# Test if an existing snapshot exists and use it if appropriate
	# And also use it if no local extracted VE is present
	if ((-f "$root/$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}.tar.gz") &&
	(((defined $vesnap->{$v}) && ($vesnap->{$v} =~ /true/i)) ||
		((defined $vesnap->{$ENV{'PBPROJ'}}) && ($vesnap->{$ENV{'PBPROJ'}} =~ /true/i))) &&
		($locsnap eq 1) &&
		($vetype ne "docker") &&
		(! -d "$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}")) {
			my $cmd1 = pb_check_req("rm",0);
			my $cmd2 = pb_check_req("mkdir",0);
			my $cmd3 = pb_check_req("tar",0);
			pb_system("$sudocmd $cmd1 -rf $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'} ; $sudocmd $cmd2 -p $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'} ; $sudocmd $cmd3 xz  -C $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'} -f $root/$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}.tar.gz","Extracting snapshot of $pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}.tar.gz under $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}");
	}

	if ($vetype ne "docker") {
		# Fix modes to allow access to the VE for pb user
		my $command = pb_check_req("chmod",0);
		pb_system("$sudocmd $command 755 $root/$pbos->{'name'} $root/$pbos->{'name'}/$pbos->{'version'} $root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}","Fixing permissions");
	}

	# If docker, create the image and remove the now temp dir except if we had one already
	if (($vetype eq "docker") && ($pbforce == 0)) {
		my $cmd1 = pb_check_req("docker",0);
		# step 0 : nothing at creation -> tag n-v-a (made below)

		if ((not defined $pbimage) || ($pbimage eq "")) {
			# Snaphot the VE to serve as an input for docker
			pb_ve_snap($pbos,$root);
			# Create the docker image from the previous bootstrap
			# Need sudo to be able to create all files correctly
			# TODO: check before that the image doesn't already exist in the docker registry
			
			my $pbimage = "$docrepo$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}";
			pb_system("$sudocmd $cmd1 import - $pbimage < $root/$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}.tar.gz");
			pb_system("$cmd1 push $pbimage");
		} else {
			# If we pass a parameter to -i, this is the name of an existing upstream image for that distro-ver-arch
			# That container should then be setup correctly which may not be the case yet
			#
			# We can probably only get those params now we have the distro context
			my ($osmindep) = pb_conf_get_if("osmindep");
			my $pkgs = pb_distro_get_param($pbos,$osmindep);
			$pkgs =~ s/,/ /g;
			my $tmpd = "$ENV{'PBTMP'}/Dockerfile";
			open(DOCKER, "> $tmpd") || die "Unable to create the docker file $tmpd";
			print DOCKER "FROM $pbimage\n";
			print DOCKER "MAINTAINER project-builder.org aka pb\n";
			print DIOCKER "ENV ftp_proxy $ENV{ftp_proxy}\n" if (defined $ENV{ftp_proxy});
			print DIOCKER "ENV http_proxy $ENV{http_proxy}\n" if (defined $ENV{http_proxy});
			# We are root in that container so no need to sudo, which is present potentially
			my $cmd2 = $pbos->{'install'};
			$cmd2 =~ s/sudo //g;
			print DOCKER "RUN $cmd2 $pkgs\n";
			close(DOCKER);
			pb_system("cd $ENV{'PBTMP'} ; $sudocmd $cmd1 build -t $docrepo$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'} .","Installing dependencies $pkgs in Docker container $docrepo$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}");
			unlink($tmpd);
		}
	}

	# Nothing more to do for VE. No real launch
} else {
	die "VE of type $vetype not supported. Report to the dev team";
}
}

#
# Return the postinstall line if needed
#

sub pb_ve_get_postinstall {

my $pbos = shift;
my $rbspi = shift;
my $vestyle = shift;
my $post = "";

# Do we have a local post-install script
if ($vestyle eq "rinse") {
	$post = "--post-install ";
} elsif ($vestyle eq "rpmbootstrap") {
	$post = "-s ";
}

my $postparam = pb_distro_get_param($pbos,$rbspi);
if ($postparam eq "") {
	$post = "";
} else {
	$post .= $postparam;
}
return($post);
}

# Snapshot the VE
sub pb_ve_snap {

my $pbos = shift;
my $root = shift;
my $tpdir = "$root/$pbos->{'name'}/$pbos->{'version'}/$pbos->{'arch'}";
pb_system("sudo tar cz -C $tpdir -f $root/$pbos->{'name'}-$pbos->{'version'}-$pbos->{'arch'}.tar.gz .","Creating a snapshot of $tpdir");
}

# Returns the docker registry to interact with
sub pb_ve_docker_registry {

my $dockerreg = shift;
my $wget = pb_check_req("wget",0);
my ($scheme, $account, $host, $port, $path) = pb_get_uri($dockerreg);
my $docreg = $scheme."://";
$docreg .= $account."@" if ((defined $account) && ($account ne ""));
$docreg .= $host;
$docreg .= ":$port" if ((defined $port) && ($port ne ""));
open(FD,"$wget $docreg -q -O -|") || die "Unable to talk to the docker registry $docreg";
my $found = undef;
while (<FD>) {
	$found = 1 if (/docker-registry/);
}
close(FD);
die "No correct docker-registry answering at $docreg. Please check your configuration" if (not defined $found);
#
return($docreg);
}

sub pb_ve_docker_get_image {

my $pbimage = shift;
my $found = 0;

die "Unable to handle an undef docker image" if (not defined $pbimage);

# Check that this docker image exists
my $cmd1 = pb_check_req("docker",0);
open(CMD, "$cmd1 images |") || die "Unable to get docker image list";
my ($repo, $tag, $id, $dummy);
while (<CMD>) {
	($repo, $tag, $id, $dummy) = split(/\s+/,$_,4);
	$found = $id if ("$repo:$tag" eq $pbimage);
}
close(CMD);
return($found);
}

sub pb_ve_get_type {

my $vetype = shift;

# Get VE context
if (not defined $vetype) {
	my ($ptr) = pb_conf_get("vetype");
	$vetype = $ptr->{$ENV{'PBPROJ'}};
}
confess "No vetype defined for $ENV{PBPROJ}" unless (defined $vetype);
pb_log(1, "Using vetype $vetype for $ENV{PBPROJ}\n");
return($vetype);
}

# Returns the docker repository to interact with
sub pb_ve_docker_repo {

my $docrepo = "";
# Check acces to registry
my ($dockerregistry) = pb_conf_get_if("dockerregistry");
if ((defined $dockerregistry) && (defined $dockerregistry->{$ENV{'PBPROJ'}})) {
	pb_ve_docker_registry($dockerregistry->{$ENV{'PBPROJ'}});
	my ($scheme, $account, $host, $port, $path) = pb_get_uri($dockerregistry->{$ENV{'PBPROJ'}}).":";
	$docrepo .= $host;
	$docrepo .= ":$port" if ((defined $port) && ($port ne ""));
	$docrepo .= "$path";
} else {
	my ($dockerrepository) = pb_conf_get("dockerrepository");
	$docrepo = $dockerrepository->{$ENV{'PBPROJ'}}.":";
}
pb_log(1,"Using Docker Repository $docrepo\n");
return($docrepo);
}


=head1 WEB SITES

The main Web site of the project is available at L<http://www.project-builder.org/>. Bug reports should be filled using the trac instance of the project at L<http://trac.project-builder.org/>.

=head1 USER MAILING LIST

None exists for the moment.

=head1 AUTHORS

The Project-Builder.org team L<http://trac.project-builder.org/> lead by Bruno Cornec L<mailto:bruno@project-builder.org>.

=head1 COPYRIGHT

Project-Builder.org is distributed under the GPL v2.0 license
described in the file C<COPYING> included with the distribution.

=cut


1;
