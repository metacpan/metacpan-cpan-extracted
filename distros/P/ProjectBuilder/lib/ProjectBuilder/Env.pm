#!/usr/bin/perl -w
#
# Project Builder Env module
# Env subroutines brought by the the Project-Builder project
# which can be easily used by pbinit scripts
#
# Copyright B. Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2
#
# $Id$
#

package ProjectBuilder::Env;

use strict 'vars';
use Data::Dumper;
use English;
use File::Basename;
use File::stat;
use POSIX qw(strftime);
use lib qw (lib);
use ProjectBuilder::Version;
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use ProjectBuilder::VCS;

# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our @ISA = qw(Exporter);
our @EXPORT = qw(pb_env_init pb_env_init_pbrc);
($VERSION,$REVISION) = pb_version_init();

=pod

=head1 NAME

ProjectBuilder::Env, part of the project-builder.org

=head1 DESCRIPTION

This modules provides environment functions suitable for pbinit calls.

=head1 USAGE

=over 4

=item B<pb_env_init_pbrc>

This function setup/use the configuration file in the HOME directory
It sets up environment variables (PBETC) 

=cut

sub pb_env_init_pbrc {

# if sudo, then get the real id of the user launching the context 
# to point to the right conf file
# Mandatory for rpmbootstrap calls
my $dir;

if (defined $ENV{'SUDO_USER'}) {
	# Home dir is the 8th field in list context
	$dir = (getpwnam($ENV{'SUDO_USER'}))[7];
} else {
	$dir = $ENV{'HOME'};
}

$ENV{'PBETC'} = "$dir/.pbrc";

if (! -f $ENV{'PBETC'}) {
	pb_log(0, "No existing $ENV{'PBETC'} found, creating one as template\n");
	open(PBRC, "> $ENV{'PBETC'}") || die "Unable to create $ENV{'PBETC'}";
	print PBRC << "EOF";
#
# Define for each project the URL of its pbconf repository
# No default option allowed here as they need to be all different
#
#pbconfurl example = svn+ssh://svn.example.org/svn/pb/projects/example/pbconf
#pbconfurl pb = svn+ssh://svn.project-builder.org/mondo/svn/pb/pbconf

# Under that dir will take place everything related to pb
# If you want to use VMs/chroot/..., then use \$ENV{'HOME'} to make it portable
# to your VMs/chroot/...
# if not defined then /var/cache
#pbdefdir default = \$ENV{'HOME'}/pb/projects
#pbdefdir pb = \$ENV{'HOME'}

# If not defined, pbconfdir is under pbdefdir/pbproj/pbconf
#pbconfdir pb = \$ENV{'HOME'}/pb/pbconf

# If not defined, pbprojdir is under pbdefdir/pbproj
# Only defined if we have access to the dev of the project
#pbprojdir example = \$ENV{'HOME'}/example/svn

# We have commit acces to these
#pburl example = cvs+ssh://user\@example.cvs.sourceforge.net:/cvsroot/example
#pburl pb = svn+ssh://svn.project-builder.org/mondo/svn/pb

# I mask my real login on the ssh machines here
#sshlogin example = user

# where to find Build System infos:
#vmpath default = /home/qemu
#vepath default = /home/rpmbootstrap
#rmpath default = /home/remote

# Overwrite generic setup
#vmport pb = 2223
#vmport example = 2224

# Info on who is packaging
#pbpackager default = William Porte <bill\@porte.org>
#pbpassphrase default = TheScretePassPhrase
#pbpassfile default = /home/williamporte/secret/passfile
EOF
	}

# We only have one configuration file for now.
pb_conf_add("$ENV{'PBETC'}");
}

=item B<pb_env_init>

This function setup the environment for project-builder.
The first parameter is the project if given on the command line.
The second parameter is a flag indicating whether we should setup up the pbconf environment or not.
The third parameter is the action passed to pb.
It sets up environement variables (PBETC, PBPROJ, PBDEFDIR, PBBUILDDIR, PBROOTDIR, PBDESTDIR, PBCONFDIR, PBPROJVER) 

=cut

sub pb_env_init {

my $proj=shift;
my $pbinit=shift;
my $action=shift;
my $pbkeep=shift || 0;
my $ver;
my $tag;

pb_conf_init($proj);
pb_env_init_pbrc();

#
# We get the pbconf file for that project 
# and use its content
#
my ($pbconf) = pb_conf_get("pbconfurl");
pb_log(2,"DEBUG pbconfurl: ".Dumper($pbconf)."\n");

my %pbconf = %$pbconf;
if (not defined $proj) {
	# Take the first as the default project
	$proj = (keys %pbconf)[0];
	if (defined $proj) {
		pb_log(1,"WARNING: using $proj as default project as none has been specified\n");
		pb_log(1,"         Please either create a pbconfurl reference for project $proj in $ENV{'PBETC'}\n");
		pb_log(1,"         or call pb with the -p project option or use the env var PBPROJ\n");
		pb_log(1,"         if you want to use another project\n");
	}
}
die "No project defined - use env var PBPROJ or -p proj or a pbconfurl entry in $ENV{'PBETC'}" if (not (defined $proj));

# That's always the environment variable that will be used
$ENV{'PBPROJ'} = $proj;
pb_log(2,"PBPROJ: $ENV{'PBPROJ'}\n");

if (not defined ($pbconf{$ENV{'PBPROJ'}})) {
	die "Please create a pbconfurl reference for project $ENV{'PBPROJ'} in $ENV{'PBETC'}\n";
}

# Adds a potential conf file now as it's less 
# important than the project conf file
my ($vmpath,$vepath,$rmpath) = pb_conf_get_if("vmpath","vepath","rmpath");
foreach my $p ($vmpath,$vepath,$rmpath) {
	if ((defined $p) && (defined $p->{$ENV{'PBPROJ'}})) {
		$p->{$ENV{'PBPROJ'}} = pb_path_expand($p->{$ENV{'PBPROJ'}});
		pb_conf_add("$p->{$ENV{'PBPROJ'}}/.pbrc") if (-f "$p->{$ENV{'PBPROJ'}}/.pbrc");
	}
}

#
# Detect the root dir for hosting all the content generated with pb
#
=pod

 Tree will look like this:

             maint pbdefdir                         PBDEFDIR            dev dir (optional)
                  |                                                        |
            ------------------------                                --------------------
            |                      |                                |                  |
         pbproj1                pbproj2             PBPROJ       pbproj1           pbproj2   PBPROJDIR
            |                                                       |
  ---------------------------------------------                ----------
  *      *        *       |        |          |                *        *
 tag    dev    pbconf    ...    bpbuild  pbdelivery PBCONFDIR dev      tag                  
  |               |                           |     PBDESTDIR           |
  ---          ------                        pbrc   PBBUILDDIR       -------
    |          |    |                                                |     |
   1.1        dev  tag                                              1.0   1.1                PBDIR
                    |
                 -------
                 |     |
                1.0   1.1                           PBROOTDIR
                       |
               ----------------------------------
               |          |           |         |
             pkg1      pbproj1.pb   pbfilter   pbcl
               |
        -----------------
        |      |        |
       rpm    deb    pbfilter


 (*) By default, if no relocation in .pbrc, dev dir is taken in the maint pbdefdir (when appropriate)
 Names under a pbproj and the corresponding pbconf should be similar

=back 

=cut

my ($pbdefdir) = pb_conf_get_if("pbdefdir");

if (not defined $ENV{'PBDEFDIR'}) {
	if ((not defined $pbdefdir) || (not defined $pbdefdir->{$ENV{'PBPROJ'}})) {
		pb_log(1,"WARNING: no pbdefdir defined, using /var/cache\n");
		pb_log(1,"         Please create a pbdefdir reference for project $ENV{'PBPROJ'} in $ENV{'PBETC'}\n");
		pb_log(1,"         if you want to use another directory\n");
		$ENV{'PBDEFDIR'} = "/var/cache";
	} else {
		# That's always the environment variable that will be used
		$ENV{'PBDEFDIR'} = $pbdefdir->{$ENV{'PBPROJ'}};
	}
}
# Expand potential env variable in it
$ENV{PBDEFDIR} = pb_path_expand($ENV{PBDEFDIR});
pb_log(2,"PBDEFDIR: $ENV{'PBDEFDIR'}\n");

# Need to do that earlier as it's used potentialy in pb_vcs_add
pb_temp_init($pbkeep);
pb_log(2,"PBTMP: $ENV{'PBTMP'}\n");

# Put under CMS the PBPROJ dir
if ($action =~ /^newproj$/) {
	if (! -d "$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}") {
		# TODO: There is also the need to do 
		# svn import "$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}" svn://repo
		# in case it doesn't exist there
		pb_mkdir_p("$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}");
	}
	pb_vcs_add($pbconf{$ENV{'PBPROJ'}},"$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}");
}

#
# Set delivery directory
#
$ENV{'PBDESTDIR'}="$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}/pbdelivery";

pb_log(2,"PBDESTDIR: $ENV{'PBDESTDIR'}\n");
#
# Removes all directory existing below the delivery dir 
# as they are temp dir only except when called from pbinit
# Files stay and have to be cleaned up manually if needed
# those files serves as communication channels between pb phases
# Removing them prevents a following phase to detect what has been done before
#
if ((-d $ENV{'PBDESTDIR'}) && ($action !~ /pbinit/)) {
	opendir(DIR,$ENV{'PBDESTDIR'}) || die "Unable to open directory $ENV{'PBDESTDIR'}: $!";
	foreach my $d (readdir(DIR)) {
		next if ($d =~ /^\./);
		next if (-f "$ENV{'PBDESTDIR'}/$d");
		pb_rm_rf("$ENV{'PBDESTDIR'}/$d") if (-d "$ENV{'PBDESTDIR'}/$d");
	}
	closedir(DIR);
}
if (! -d "$ENV{'PBDESTDIR'}") {
	pb_mkdir_p($ENV{'PBDESTDIR'});
}

#
# Set build directory
#
$ENV{'PBBUILDDIR'}="$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}/pbbuild";
if (! -d "$ENV{'PBBUILDDIR'}") {
	pb_mkdir_p($ENV{'PBBUILDDIR'});
}

pb_log(2,"PBBUILDDIR: $ENV{'PBBUILDDIR'}\n");

return if ($action =~ /^clean$/);
#
# The following part is only useful when in sbx|cms2something or newsomething
# In VMs/VEs/RMs we want to skip that by providing good env vars.
# return values in that case are useless
#

if ($action =~ /^(cms2|sbx2|newver|pbinit|newproj|announce|checkssh|cleanssh|getconf|setupve)/) {

	#
	# Check pbconf cms compliance
	#
	pb_vcs_compliant("pbconfdir",'PBCONFDIR',"$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}/pbconf",$pbconf{$ENV{'PBPROJ'}},$pbinit);
	my ($scheme, $account, $host, $port, $path) = pb_get_uri($pbconf{$ENV{'PBPROJ'}});

	# Check where is our PBROOTDIR (release tag name can't be guessed the first time)
	#
	if (not defined $ENV{'PBROOTDIR'}) {
		if (! -f ("$ENV{'PBDESTDIR'}/pbrc")) {
			$ENV{'PBROOTDIR'} = "$ENV{'PBCONFDIR'}";
			pb_log(1,"WARNING: no pbroot defined, using $ENV{'PBROOTDIR'}\n");
			pb_log(1,"         Please use -r release if you want to use another release\n");
			die "No directory found under $ENV{'PBCONFDIR'}" if (not defined $ENV{'PBROOTDIR'});
		} else {
			my ($pbroot) = pb_conf_read_if("$ENV{'PBDESTDIR'}/pbrc","pbroot");
			# That's always the environment variable that will be used
			die "Please remove inconsistent $ENV{'PBDESTDIR'}/pbrc" if ((not defined $pbroot) || (not defined $pbroot->{$ENV{'PBPROJ'}}));
			$ENV{'PBROOTDIR'} = $pbroot->{$ENV{'PBPROJ'}};
		}
	} else {
		# transform in full path if relative
		$ENV{'PBROOTDIR'} = "$ENV{'PBCONFDIR'}/$ENV{'PBROOTDIR'}" if ($ENV{'PBROOTDIR'} !~ /^\//);
		# If git, then versions are in branch not in dirs, except for git+svn
		$ENV{'PBROOTDIR'} = "$ENV{'PBCONFDIR'}" if (($scheme =~ /^git/) && ($scheme =~ /^svn/));
		pb_mkdir_p($ENV{'PBROOTDIR'}) if (defined $pbinit);
		die "$ENV{'PBROOTDIR'} is not a directory" if (not -d $ENV{'PBROOTDIR'});
	}
	pb_log(1,"PBROOTDIR=$ENV{'PBROOTDIR'}\n");

	# Adds that conf file to the list to consider
	pb_conf_add("$ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb") if (-f "$ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb");

	return if ($action =~ /^(newver|getconf|setupve)$/);

	my %version = ();
	my %defpkgdir = ();
	my %extpkgdir = ();
	my %filteredfiles = ();
	my %supfiles = ();
	
	if ((-f "$ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb") and (not defined $pbinit)) {

		# List of pkg to build by default (mandatory)
		# TODO: projtag could be with a 1 default value
		my ($defpkgdir,$pbpackager, $pkgv, $pkgt) = pb_conf_get("defpkgdir","pbpackager","projver","projtag");
		# List of additional pkg to build when all is called (optional)
		# Valid version names (optional)
		# List of files to filter (optional)
		# Project version and tag (optional)
		my ($extpkgdir, $version, $filteredfiles, $supfiles) = pb_conf_get_if("extpkgdir","version","filteredfiles","supfiles");
		pb_log(2,"DEBUG: defpkgdir: ".Dumper($defpkgdir)."\n");
		pb_log(2,"DEBUG: extpkgdir: ".Dumper($extpkgdir)."\n");
		pb_log(2,"DEBUG: version: ".Dumper($version)."\n");
		pb_log(2,"DEBUG: filteredfiles: ".Dumper($filteredfiles)."\n");
		pb_log(2,"DEBUG: supfiles: ".Dumper($supfiles)."\n");
		# Global
		%defpkgdir = %$defpkgdir;
		%extpkgdir = %$extpkgdir if (defined $extpkgdir);
		%version = %$version if (defined $version);
		%filteredfiles = %$filteredfiles if (defined $filteredfiles);
		%supfiles = %$supfiles if (defined $supfiles);
		#
		# Get global Version/Tag
		#
		if (not defined $ENV{'PBPROJVER'}) {
			if ((defined $pkgv) && (defined $pkgv->{$ENV{'PBPROJ'}})) {
				$ENV{'PBPROJVER'}=$pkgv->{$ENV{'PBPROJ'}};
			} else {
				die "No projver found in $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb";
			}
		}
		die "Invalid version name $ENV{'PBPROJVER'} in $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb" if (($ENV{'PBPROJVER'} !~ /[0-9.]+/) && (defined $version) && ($ENV{'PBPROJVER'} =~ /$version{$ENV{'PBPROJ'}}/));
		
		if (not defined $ENV{'PBPROJTAG'}) {
			if ((defined $pkgt) && (defined $pkgt->{$ENV{'PBPROJ'}})) {
				$ENV{'PBPROJTAG'}=$pkgt->{$ENV{'PBPROJ'}};
			} else {
				die "No projtag found in $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb";
			}
		}
		die "Invalid tag name $ENV{'PBPROJTAG'} in $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb" if ($ENV{'PBPROJTAG'} !~ /[0-9.]+/);
	
	
		if (not defined $ENV{'PBPACKAGER'}) {
			if ((defined $pbpackager) && (defined $pbpackager->{$ENV{'PBPROJ'}})) {
				$ENV{'PBPACKAGER'}=$pbpackager->{$ENV{'PBPROJ'}};
			} else {
				die "No pbpackager found in $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb";
			}
		}
	} else {
		if (defined $pbinit) {
			my @pkgs = @ARGV;
			@pkgs = ("pkg1") if (not @pkgs);
	
			open(CONF,"> $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb") || die "Unable to create $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb";
			print CONF << "EOF";
#
# Project Builder configuration file
# For project $ENV{'PBPROJ'}
#
# \$Id\$
#

#
# What is the project URL
#
#pburl $ENV{'PBPROJ'} = svn://svn.$ENV{'PBPROJ'}.org/$ENV{'PBPROJ'}/devel
#pburl $ENV{'PBPROJ'} = svn://svn+ssh.$ENV{'PBPROJ'}.org/$ENV{'PBPROJ'}/devel
#pburl $ENV{'PBPROJ'} = cvs://cvs.$ENV{'PBPROJ'}.org/$ENV{'PBPROJ'}/devel
#pburl $ENV{'PBPROJ'} = http://www.$ENV{'PBPROJ'}.org/src/$ENV{'PBPROJ'}-devel.tar.gz
#pburl $ENV{'PBPROJ'} = ftp://ftp.$ENV{'PBPROJ'}.org/src/$ENV{'PBPROJ'}-devel.tar.gz
#pburl $ENV{'PBPROJ'} = file:///src/$ENV{'PBPROJ'}-devel.tar.gz
#pburl $ENV{'PBPROJ'} = dir:///src/$ENV{'PBPROJ'}-devel

# Repository
#pbrepo $ENV{'PBPROJ'} = ftp://ftp.$ENV{'PBPROJ'}.org
#pbml $ENV{'PBPROJ'} = $ENV{'PBPROJ'}-announce\@lists.$ENV{'PBPROJ'}.org
#pbsmtp $ENV{'PBPROJ'} = localhost
#pbgpgcheck $ENV{'PBPROJ'} = 1
# For distro supporting it, which area is used
#projcomponent $ENV{'PBPROJ'} = main

# Check whether project is well formed 
# when downloading from ftp/http/...
# (containing already a directory with the project-version name)
#pbwf $ENV{'PBPROJ'} = 1

# Do we check GPG keys
#pbgpgcheck $ENV{'PBPROJ'} = 1

#
# Packager label
#
#pbpackager $ENV{'PBPROJ'} = William Porte <bill\@$ENV{'PBPROJ'}.org>
#

# For delivery to a machine by SSH (potentially the FTP server)
# Needs hostname, account and directory
#
#sshhost $ENV{'PBPROJ'} = www.$ENV{'PBPROJ'}.org
#sshlogin $ENV{'PBPROJ'} = bill
#sshdir $ENV{'PBPROJ'} = /$ENV{'PBPROJ'}/ftp
#sshport $ENV{'PBPROJ'} = 22

#
# For Virtual machines management
# Naming convention to follow: distribution name (as per ProjectBuilder::Distribution)
# followed by '-' and by release number
# followed by '-' and by architecture
# a .vmtype extension will be added to the resulting string
# a QEMU rhel-3-i286 here means that the VM will be named rhel-3-i386.qemu
#
#vmlist $ENV{'PBPROJ'} = asianux-2-i386,asianux-3-i386,mandrake-10.1-i386,mandrake-10.2-i386,mandriva-2006.0-i386,mandriva-2007.0-i386,mandriva-2007.1-i386,mandriva-2008.0-i386,mandriva-2008.1-i386,mandriva-2009.0-i386,mandriva-2009.1-i386,mandriva-2010.0-i386,mandriva-2010.1-i386,redhat-7.3-i386,redhat-9-i386,fedora-4-i386,fedora-5-i386,fedora-6-i386,fedora-7-i386,fedora-8-i386,fedora-9-i386,fedora-10-i386,fedora-11-i386,fedora-12-i386,fedora-13-i386,fedora-14-i386,fedora-15-i386,fedora-16-i386,fedora-17-i386,fedora-18-i386,rhel-2-i386,rhel-3-i386,rhel-4-i386,rhel-5-i386,rhel-6-i386,suse-10.0-i386,suse-10.1-i386,opensuse-10.2-i386,opensuse-10.3-i386,opensuse-11.0-i386,opensuse-11.1-i386,opensuse-11.2-i386,opensuse-11.3-i386,opensuse-11.4-i386,opensuse-12.1-i386,opensuse-12.2-i386,opensuse-12.3-i386,sles-9-i386,sles-10-i386,sles-11-i386,gentoo-nover-i386,debian-3.1-i386,debian-4.0-i386,debian-5.0-i386,debian-6.0-i386,ubuntu-6.06-i386,ubuntu-7.04-i386,ubuntu-7.10-i386,ubuntu-8.04-i386,ubuntu-8.10-i386,ubuntu-9.04-i386,ubuntu-9.10-i386,ubuntu-10.04-i386,ubuntu-10.10-i386,ubuntu-11.04-i386,ubuntu-11.10-i386,ubuntu-12.04-i386,ubuntu-12.10-i386,solaris-10-i386,asianux-2-x86_64,asianux-3-x86_64,mandriva-2007.0-x86_64,mandriva-2007.1-x86_64,mandriva-2008.0-x86_64,mandriva-2008.1-x86_64,mandriva-2009.0-x86_64,mandriva-2009.1-x86_64,mandriva-2010.0-x86_64,mandriva-2010.1-x86_64,mageia-1-i386,mageia-2-i386,mageia-1-x86_64,mageia-2-x86_64,fedora-6-x86_64,fedora-7-x86_64,fedora-8-x86_64,fedora-9-x86_64,fedora-10-x86_64,fedora-11-x86_64,fedora-12-x86_64,fedora-13-x86_64,fedora-14-x86_64,fedora-15-x86_64,fedora-16-x86_64,fedora-17-x86_64,fedora-18-x86_64,rhel-3-x86_64,rhel-4-x86_64,rhel-5-x86_64,rhel-6-x86_64,opensuse-10.2-x86_64,opensuse-10.3-x86_64,opensuse-11.0-x86_64,opensuse-11.1-x86_64,opensuse-11.2-x86_64,opensuse-11.3-x86_64,opensuse-11.4-x86_64,opensuse-12.1-x86_64,opensuse-12.2-x86_64,opensuse-12.3-i386,sles-10-x86_64,sles-11-x86_64,gentoo-nover-x86_64,debian-4.0-x86_64,debian-5.0-x86_64,debian-6.0-x86_64,ubuntu-7.04-x86_64,ubuntu-7.10-x86_64,ubuntu-8.04-x86_64,ubuntu-8.10-x86_64,ubuntu-9.04-x86_64,ubuntu-9.10-x86_64,ubuntu-10.04-x86_64,ubuntu-10.10-x86_64,ubuntu-11.04-x86_64,ubuntu-11.10-x86_64,ubuntu-12.04-x86_64,ubuntu-12.10-x86_64

#
# Valid values for vmtype are
# qemu, (vmware, xen, ... TBD)
#vmtype $ENV{'PBPROJ'} = qemu

# Hash for VM stuff on vmtype
#vmntp default = pool.ntp.org

# We suppose we can commmunicate with the VM through SSH
#vmhost $ENV{'PBPROJ'} = localhost
#vmlogin $ENV{'PBPROJ'} = pb
#vmport $ENV{'PBPROJ'} = 2222

# Timeout to wait when VM is launched/stopped
#vmtmout default = 120

# per VMs needed paramaters
#vmopt $ENV{'PBPROJ'} = -m 384 -daemonize
#vmpath $ENV{'PBPROJ'} = /home/qemu
#vmsize $ENV{'PBPROJ'} = 5G

# 
# For Virtual environment management
# Naming convention to follow: distribution name (as per ProjectBuilder::Distribution)
# followed by '-' and by release number
# followed by '-' and by architecture
# a .vetype extension will be added to the resulting string
# a chroot rhel-3-i286 here means that the VE will be named rhel-3-i386.chroot
#
#velist $ENV{'PBPROJ'} = fedora-7-i386

# VE params
#vetype $ENV{'PBPROJ'} = chroot
#ventp default = pool.ntp.org
#velogin $ENV{'PBPROJ'} = pb
#vepath $ENV{'PBPROJ'} = /var/cache/rpmbootstrap
#rbsconf $ENV{'PBPROJ'} = /etc/mock
#verebuild $ENV{'PBPROJ'} = false

#
# Global version/tag for the project
#
#projver $ENV{'PBPROJ'} = devel
#projtag $ENV{'PBPROJ'} = 1

# Hash of valid version names

# Additional repository to add at build time
# addrepo centos-5-x86_64 = http://packages.sw.be/rpmforge-release/rpmforge-release-0.3.6-1.el5.rf.x86_64.rpm,ftp://ftp.project-builder.org/centos/5/pb.repo
# addrepo centos-5-x86_64 = http://packages.sw.be/rpmforge-release/rpmforge-release-0.3.6-1.el5.rf.x86_64.rpm,ftp://ftp.project-builder.org/centos/5/pb.repo
#version $ENV{'PBPROJ'} = devel,stable

# Is it a test version or a production version
testver $ENV{'PBPROJ'} = true
# Which upper target dir for delivery
delivery $ENV{'PBPROJ'} = test

# Additional repository to add at build time
# addrepo centos-5-x86_64 = http://packages.sw.be/rpmforge-release/rpmforge-release-0.3.6-1.el5.rf.x86_64.rpm,ftp://ftp.project-builder.org/centos/5/pb.repo
# addrepo centos-4-x86_64 = http://packages.sw.be/rpmforge-release/rpmforge-release-0.3.6-1.el4.rf.x86_64.rpm,ftp://ftp.project-builder.org/centos/4/pb.repo

# Adapt to your needs:
# Optional if you need to overwrite the global values above
#
EOF
		
			foreach my $pp (@pkgs) {
				print CONF << "EOF";
#pkgver $pp = stable
#pkgtag $pp = 3
EOF
			}
			foreach my $pp (@pkgs) {
				print CONF << "EOF";
# Hash of default package/package directory
#defpkgdir $pp = dir-$pp
EOF
			}
	
			print CONF << "EOF";
# Hash of additional package/package directory
#extpkgdir minor-pkg = dir-minor-pkg

# List of files per pkg on which to apply filters
# Files are mentioned relatively to pbroot/defpkgdir
EOF
			foreach my $pp (@pkgs) {
				print CONF << "EOF";
#filteredfiles $pp = Makefile.PL,configure.in,install.sh,$pp.8
#supfiles $pp = $pp.init

# For perl modules, names are different depending on distro
# Here perl-xxx for RPMs, libxxx-perl for debs, ...
# So the package name is indeed virtual
#namingtype $pp = perl
EOF
			}
			close(CONF);
			pb_mkdir_p("$ENV{'PBROOTDIR'}/pbfilter");
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/all.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/all.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for all files
#
#
# PBREPO is replaced by the root URL to access the repository
filter PBREPO = \$pb->{'repo'}

# PBSRC is replaced by the source package location after the repo
filter PBSRC = src/%{srcname}-%{version}\$pb->{'extdir'}.tar.gz

# PBVER is replaced by the version (\$pb->{'ver'} in code)
filter PBVER = \$pb->{'ver'}

# PBDATE is replaced by the date (\$pb->{'date'} in code)
filter PBDATE = \$pb->{'date'}

# PBEXTDIR is replaced by the testdir extension if needed (\$pb->{'extdir'} in code)
filter PBEXTDIR = \$pb->{'extdir'}

# PBPATCHSRC is replaced by the patches names if value is yes. Patches are located under the pbpatch dir of the pkg.
#filter PBPATCHSRC = yes

# PBPATCHCMD is replaced by the patches commands if value is yes
#filter PBPATCHCMD = yes

# PBMULTISRC is replaced by the sources names if value is yes. Sources are located under the pbsrc dir of the pkg.
#filter PBMULTISRC = yes

# PBTAG is replaced by the tag (\$pb->{'tag'} in code)
filter PBTAG = \$pb->{'tag'}

# PBREV is replaced by the revision (\$pb->{'rev'} in code)
filter PBREV = \$pb->{'rev'}

# PBREALPKG is replaced by the package name (\$pb->{'realpkg'} in code)
filter PBREALPKG = \$pb->{'realpkg'}

# PBPKG is replaced by the package name (\$pb->{'pkg'} in code)
filter PBPKG = \$pb->{'pkg'}

# PBPROJ is replaced by the project name (\$pb->{'proj'} in code)
filter PBPROJ = \$pb->{'proj'}

# PBPACKAGER is replaced by the packager name (\$pb->{'packager'} in code)
filter PBPACKAGER = \$pb->{'packager'}

# PBDESC contains the description of the package
#filter PBDESC = Bla-Bla                                                 \
# with a trailing \, the variable can be multi-line.                     \
# only the trailing \'s will be removed, the leading spaces,             \
# trailing spaces, and newlines will remain except on the                \
# last line.  You can use dollar slash as a way to introduce carraige    \
# return (perl syntax).                                                  \
# You can use transform e.g. in rpm.pbf to adjust spaces

# PBSUMMARY contains a short single line description of the package
#filter PBSUMMARY = Bla

# PBURL contains the URL of the Web site of the project
#filter PBURL = http://www.$ENV{'PBPROJ'}.org

# PBLOG is replaced by the changelog if value is yes
# and should be last as when used we need the %pb hash filled
#filter PBLOG = yes

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/rpm.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/rpm.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for rpm build
#

# PBGRP is replaced by the RPM group of apps
#filter PBGRP = Applications/Archiving

# PBLIC is replaced by the license of the application
#filter PBLIC = GPL

# PBDEP is replaced by the list of dependencies
#filter PBDEP =

# PBBDEP is replaced by the list of build dependencies
#filter PBBDEP =

# PBSUF is replaced by the package suffix (\$pb->{'suf'} in code)
filter PBSUF = \$pb->{'suf'}

# PBOBS is replaced by the Obsolete line
#filter PBOBS =

# transform a variable from the key on the right to the key on the left using the perl expression
# after the input key name.  Useful for taking multi-line documentation and removing trailing spaces
# or leading spaces.
#transform PBDESC = PBDESC_raw s/\\s+\\n/\\n/go;

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/fedora.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/fedora.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for rpm build
#

# PBGRP is replaced by the RPM group of apps
# Cf: http://fedoraproject.org/wiki/RPMGroups
#filter PBGRP = Applications/Archiving

# PBLIC is replaced by the license of the application
# Cf: http://fedoraproject.org/wiki/Licensing
#filter PBLIC = GPLv2+

# PBDEP is replaced by the list of dependencies
#filter PBDEP =

# PBBDEP is replaced by the list of build dependencies
#filter PBBDEP =

# PBSUF is replaced by the package suffix (\$pb->{'suf'} in code)
filter PBSUF = %{dist}

# PBOBS is replaced by the Obsolete line
#filter PBOBS =

EOF
			close(CONF);
			foreach my $i (1..7) {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/fedora-$i.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/fedora-$i.pbf";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for old fedora build
#

# PBSUF is replaced by the package suffix (\$pb->{'suf'} in code)
filter PBSUF = \$pb->{'suf'}

EOF
				close(CONF);
			}
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/deb.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/deb.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBGRP is replaced by the group of apps
filter PBGRP = utils

# PBLIC is replaced by the license of the application
# Cf: http://www.debian.org/legal/licenses/
#filter PBLIC = GPL

# PBDEP is replaced by the list of dependencies
#filter PBDEP =

# PBBDEP is replaced by the list of build dependencies
#filter PBBDEP =

# PBSUG is replaced by the list of suggestions
#filter PBSUG =

# PBREC is replaced by the list of recommandations
#filter PBREC =

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/debian-3.1.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/debian-3.1.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.6.1

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 4

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/debian-4.0.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/debian-4.0.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.6.1

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 5

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/debian-5.0.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/debian-5.0.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.8.0

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 7

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/debian-6.0.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/debian-6.0.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.8.0

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 7

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/debian-7.0.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/debian-7.0.pbf";
			print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.9.4

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 9

EOF
			close(CONF);
			# 6?
			foreach my $ubv ("debian.pbf") {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/$ubv") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/$ubv";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for debian build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.8.0

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 7

EOF
				close(CONF);
			}
			foreach my $ubv ("ubuntu-6.06.pbf","ubuntu-7.04.pbf","ubuntu-7.10.pbf") {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/$ubv") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/$ubv";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for ubuntu build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.6.2

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 4

EOF
				close(CONF);
			}
			foreach my $ubv ("ubuntu-8.04.pbf","ubuntu-8.10.pbf") {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/$ubv") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/$ubv";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for ubuntu build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.7.3

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 4

EOF
				close(CONF);
			}
			foreach my $ubv ("ubuntu-9.04.pbf") {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/$ubv") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/$ubv";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for ubuntu build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.8.0

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 4

EOF
				close(CONF);
			}
			# 9.10, 10.04, 10.10
			foreach my $ubv ("ubuntu.pbf") {
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/$ubv") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/$ubv";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for ubuntu build
#
# PBDEBSTD is replaced by the Debian standard version
filter PBDEBSTD = 3.8.3

# PBDEBCOMP is replaced by the Debian Compatibility value
filter PBDEBCOMP = 7

EOF
				close(CONF);
			}
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/md.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/md.pbf";
			print CONF << "EOF";
# Specific group for Mandriva for $ENV{'PBPROJ'}
# Cf: http://wiki.mandriva.com/en/Development/Packaging/Groups
#filter PBGRP = Archiving/Backup

# PBLIC is replaced by the license of the application
# Cf: http://wiki.mandriva.com/en/Development/Packaging/Licenses
#filter PBLIC = GPL

EOF
			close(CONF);
			open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/novell.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/novell.pbf";
			print CONF << "EOF";
# Specific group for SuSE for $ENV{'PBPROJ'}
# Cf: http://en.opensuse.org/SUSE_Package_Conventions/RPM_Groups
#filter PBGRP = Productivity/Archiving/Backup

# PBLIC is replaced by the license of the application
# Cf: http://en.opensuse.org/Packaging/SUSE_Package_Conventions/RPM_Style#1.6._License_Tag
#filter PBLIC = GPL

EOF
			close(CONF);
			foreach my $pp (@pkgs) {
				pb_mkdir_p("$ENV{'PBROOTDIR'}/$pp/deb");
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/control") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/control";
				print CONF << "EOF";
Source: PBPKG
# http://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
Section: PBGRP
Priority: optional
Maintainer: PBPACKAGER
Build-Depends: debhelper (>= 4.2.20), PBBDEP
Standards-Version: PBDEBSTD
Vcs-Svn: svn://svn.PBPROJ.org/svn/PBVER/PBPKG
Vcs-Browser: http://trac.PBPROJ.org/browser/PBVER/PBPKG
Homepage: PBURL

Package: PBPKG
Architecture: amd64 i386 ia64
# http://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
Section: PBGRP
Priority: optional
Depends: \${shlibs:Depends}, \${misc:Depends}, PBDEP
Recommends: PBREC
Suggests: PBSUG
Description: PBSUMMARY
 PBDESC
 .

EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/copyright") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/copyright";
				print CONF << "EOF";
This package is debianized by PBPACKAGER
`date`

The current upstream source was downloaded from
PBREPO.

Upstream Authors: Put their name here

Copyright:

   This package is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 dated June, 1991.

   This package is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this package; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
   MA 02110-1301, USA.

On Debian systems, the complete text of the GNU General
Public License can be found in /usr/share/common-licenses/GPL.

EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/changelog") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/changelog";
				print CONF << "EOF";
PBLOG
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/compat") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/compat";
				print CONF << "EOF";
PBDEBCOMP
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/$pp.dirs") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/$pp.dirs";
				print CONF << "EOF";
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/$pp.docs") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/$pp.docs";
				print CONF << "EOF";
INSTALL
COPYING
AUTHORS
NEWS
README
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/deb/rules") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/deb/rules";
				print CONF << 'EOF';
#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
# GNU copyright 1997 to 1999 by Joey Hess.
#
# $Id$
#

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# Define package name variable for a one-stop change.
PACKAGE_NAME = PBPKG

# These are used for cross-compiling and for saving the configure script
# from having to guess our platform (since we know it already)
DEB_HOST_GNU_TYPE   ?= $(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)
DEB_BUILD_GNU_TYPE  ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_TYPE)

CFLAGS = -Wall -g

ifneq (,$(findstring noopt,$(DEB_BUILD_OPTIONS)))
	CFLAGS += -O0
else
	CFLAGS += -O2
endif
ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTIONS)))
	INSTALL_PROGRAM += -s
endif

config.status: configure
	dh_testdir

	# Configure the package.
	CFLAGS="$(CFLAGS)" ./configure --host=$(DEB_HOST_GNU_TYPE) --build=$(DEB_BUILD_GNU_TYPE) --prefix=/usr --mandir=\$${prefix}/share/man

# Build both architecture dependent and independent
build: build-arch build-indep

# Build architecture dependent
build-arch: build-arch-stamp

build-arch-stamp:  config.status
	dh_testdir

	# Compile the package.
	$(MAKE)

	touch build-stamp

# Build architecture independent
build-indep: build-indep-stamp

build-indep-stamp:  config.status
	# Nothing to do, the only indep item is the manual which is available as html in original source
	touch build-indep-stamp

# Clean up
clean:
	dh_testdir
	dh_testroot
	rm -f build-arch-stamp build-indep-stamp #CONFIGURE-STAMP#
	# Clean temporary document directory
	rm -rf debian/doc-temp
	# Clean up.
	-$(MAKE) distclean
	rm -f config.log
ifneq "$(wildcard /usr/share/misc/config.sub)" ""
	cp -f /usr/share/misc/config.sub config.sub
endif
ifneq "$(wildcard /usr/share/misc/config.guess)" ""
	cp -f /usr/share/misc/config.guess config.guess
endif

	dh_clean

# Install architecture dependent and independent
install: install-arch install-indep

# Install architecture dependent
install-arch: build-arch
	dh_testdir
	dh_testroot
	dh_clean -k -s
	dh_installdirs -s

	# Install the package files into build directory:
	# - start with upstream make install
	$(MAKE) install prefix=$(CURDIR)/debian/$(PACKAGE_NAME)/usr mandir=$(CURDIR)/debian/$(PACKAGE_NAME)/usr/share/man
	# - copy html manual to temporary location for renaming
	mkdir -p debian/doc-temp
	dh_install -s

# Install architecture independent
install-indep: build-indep
	dh_testdir
	dh_testroot
	dh_clean -k -i
	dh_installdirs -i
	dh_install -i

# Must not depend on anything. This is to be called by
# binary-arch/binary-indep
# in another 'make' thread.
binary-common:
	dh_testdir
	dh_testroot
	dh_installchangelogs ChangeLog
	dh_installdocs
	dh_installman
	dh_link
	dh_strip
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_shlibdeps
	dh_gencontrol
	dh_md5sums
	dh_builddeb

# Build architecture independant packages using the common target.
binary-indep: build-indep install-indep
	$(MAKE) -f debian/rules DH_OPTIONS=-i binary-common

# Build architecture dependant packages using the common target.
binary-arch: build-arch install-arch
	$(MAKE) -f debian/rules DH_OPTIONS=-a binary-common

# Build architecture depdendent and independent packages
binary: binary-arch binary-indep
.PHONY: clean binary

EOF
				close(CONF);
				pb_mkdir_p("$ENV{'PBROOTDIR'}/$pp/rpm");
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/rpm/$pp.spec") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/rpm/$pp.spec";
				print CONF << 'EOF';
#
# $Id$
#
# Used if virtual name != real name (perl, ...) - replace PBPKG by PBREALPKG in the line below
%define srcname	PBPKG

Summary:        PBSUMMARY
Summary(fr):    french bla-bla

Name:           PBREALPKG
Version:        PBVER
Release:        PBTAGPBSUF
License:        PBLIC
Group:          PBGRP
Url:            PBURL
Source:         PBREPO/PBSRC
#PBPATCHSRC
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(id -u -n)
#Requires:       PBDEP
#BuildRequires:       PBBDEP

%description
PBDESC

%description -l fr
french desc

%prep
%setup -q %{name}-%{version}PBEXTDIR
# Used if virtual name != real name (perl, ...)
#%setup -q -n %{srcname}-%{version}PBEXTDIR
#PBPATCHCMD

%build
%configure
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc ChangeLog
%doc INSTALL COPYING README AUTHORS NEWS

%changelog
PBLOG

EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/pbfilter/pkg.pbf") || die "Unable to create $ENV{'PBROOTDIR'}/pbfilter/pkg.pbf";
				print CONF << "EOF";
#
# \$Id\$
#
# Filter for pkg build
#
# Solaris package name (VENDOR : 4 letters in uppercase, SOFT : 8 letters in lowercase)
filter PBSOLPKG = SUNWsoftware

EOF
				close(CONF);
				pb_mkdir_p("$ENV{'PBROOTDIR'}/$pp/pbfilter");
				pb_mkdir_p("$ENV{'PBROOTDIR'}/$pp/pkg");
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/pkg/pkginfo") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/pkg/pkginfo";
				print CONF << 'EOF';
#
# $Id$
#
PKG="PBSOLPKG"
NAME="PBREALPKG"
VERSION="PBVER"
# all or i386
ARCH="all"
CATEGORY="application"
DESC="PBSUMMARY"
EMAIL="PBPACKAGER"
VENDOR="PBPACKAGER"
HOTLINE="PBURL"
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/pkg/pbbuild") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/pkg/pbbuild";
				print CONF << 'EOF';
#
# $Id$
#
#perl Makefile.PL INSTALLDIRS=vendor
./configure --prefix=/usr
make
make install DESTDIR=\$1
EOF
				close(CONF);
				open(CONF,"> $ENV{'PBROOTDIR'}/$pp/pkg/depend") || die "Unable to create $ENV{'PBROOTDIR'}/$pp/pkg/depend";
				print CONF << 'EOF';
#
# $Id$
#
#P SUNWperl584core       Perl 5.8.4 (core)
EOF
				close(CONF);
	
			}
			pb_vcs_add($pbconf{$ENV{'PBPROJ'}},$ENV{'PBCONFDIR'});
			my $msg = "updated to ".basename("$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}");
			$msg = "Project $ENV{'PBPROJ'} creation" if (defined $pbinit);
			pb_vcs_checkin($pbconf{$ENV{'PBPROJ'}},"$ENV{'PBDEFDIR'}/$ENV{'PBPROJ'}",$msg);
		} else {
			pb_log(0,"ERROR: no pbroot defined, used $ENV{'PBROOTDIR'}, without finding $ENV{'PBPROJ'}.pb in it\n");
			pb_log(0,"       Please use -r release in order to be able to initialize your environment correctly\n");
			die "Unable to open $ENV{'PBROOTDIR'}/$ENV{'PBPROJ'}.pb";
		}
	}
	umask 0022;
	return(\%filteredfiles, \%supfiles, \%defpkgdir, \%extpkgdir);
} elsif ($action =~ /^(newv|setupv)/) {
	# No PBDESTDIR yet so doing nothing
	return;
} else {
	# Setup the variables from what has been stored at the end of cms2build
	my ($var) = pb_conf_read("$ENV{'PBDESTDIR'}/pbrc","pbroot");
	$ENV{'PBROOTDIR'} = $var->{$ENV{'PBPROJ'}};

	($var) = pb_conf_read("$ENV{'PBDESTDIR'}/pbrc","projver");
	$ENV{'PBPROJVER'} = $var->{$ENV{'PBPROJ'}};

	($var) = pb_conf_read("$ENV{'PBDESTDIR'}/pbrc","projtag");
	$ENV{'PBPROJTAG'} = $var->{$ENV{'PBPROJ'}};

	($var) = pb_conf_read("$ENV{'PBDESTDIR'}/pbrc","pbpackager");
	$ENV{'PBPACKAGER'} = $var->{$ENV{'PBPROJ'}};

	return;
}
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
