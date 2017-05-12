#!/usr/bin/perl -w
#
# Project Builder VCS module
# VCS subroutines brought by the the Project-Builder project
# which can be easily used across projects needing to perform 
# VCS related operations
#
# $Id$
#
# Copyright B. Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2

package ProjectBuilder::VCS;

use strict 'vars';
use Carp 'confess';
use Cwd 'abs_path';
use Data::Dumper;
use English;
use File::Basename;
use File::Copy;
use POSIX qw(strftime);
use lib qw (lib);
use ProjectBuilder::Version;
use ProjectBuilder::Base;
use ProjectBuilder::Conf;

# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our @ISA = qw(Exporter);
our @EXPORT = qw(pb_vcs_export pb_vcs_get_uri pb_vcs_copy pb_vcs_checkout pb_vcs_up pb_vcs_checkin pb_vcs_isdiff pb_vcs_add pb_vcs_add_if_not_in pb_vcs_cmd pb_vcs_compliant);
($VERSION,$REVISION) = pb_version_init();

=pod

=head1 NAME

ProjectBuilder::VCS, part of the project-builder.org

=head1 DESCRIPTION

This modules provides version control system functions.

=head1 USAGE

=over 4

=item B<pb_vcs_export>

This function exports a VCS content to a directory.
The first parameter is the URL of the VCS content.
The second parameter is the directory in which it is locally exposed (result of a checkout). If undef, then use the original VCS content.
The third parameter is the directory where we want to deliver it (result of export).
It returns the original tar file if we need to preserve it and undef if we use the produced one.

=cut

sub pb_vcs_export {

my $uri = shift;
my $source = shift;
my $destdir = shift;
my $tmp;
my $tmp1;

pb_log(1,"pb_vcs_export uri: $uri - destdir: $destdir\n");
pb_log(1,"pb_vcs_export source: $source\n") if (defined $source);
my @date = pb_get_date();
# If it's not flat, then we have a real uri as source
my ($scheme, $account, $host, $port, $path) = pb_get_uri($uri);
my $vcscmd = pb_vcs_cmd($scheme);
$uri = pb_vcs_mod_socks($uri);

if ($scheme =~ /^svn/) {
	if (defined $source) {
		if (-d $source) {
			$tmp = $destdir;
		} else {
			$tmp = "$destdir/".basename($source);
		}
		$source = pb_vcs_mod_htftp($source,"svn");
		pb_system("$vcscmd export $source $tmp","Exporting $source from $scheme to $tmp ");
	} else {
		$uri = pb_vcs_mod_htftp($uri,"svn");
		pb_system("$vcscmd export $uri $destdir","Exporting $uri from $scheme to $destdir ");
	}
} elsif ($scheme eq "svk") {
	my $src = $source;
	if (defined $source) {
		if (-d $source) {
			$tmp = $destdir;
		} else {
			$tmp = "$destdir/".basename($source);
			$src = dirname($source);
		}
		$source = pb_vcs_mod_htftp($source,"svk");
		# This doesn't exist !
		# pb_system("$vcscmd export $path $tmp","Exporting $path from $scheme to $tmp ");
		pb_log(4,"$uri,$source,$destdir,$scheme, $account, $host, $port, $path,$tmp");
		if (-d $source) {
			pb_system("mkdir -p $tmp ; cd $tmp; tar -cf - -C $source . | tar xf -","Exporting $source from $scheme to $tmp ");
		} else {
			# If source is file do not use -C with source
			pb_system("mkdir -p ".dirname($tmp)." ; cd ".dirname($tmp)."; tar -cf - -C $src ".basename($source)." | tar xf -","Exporting $src/".basename($source)." from $scheme to $tmp ");
		}
	} else {
		# Look at svk admin hotcopy
		confess "Unable to export from svk without a source defined";
	}
} elsif ($scheme eq "dir") {
	pb_system("cp -r $path $destdir","Copying $uri from DIR to $destdir ");
} elsif (($scheme eq "http") || ($scheme eq "ftp")) {
	my $f = basename($path);
	unlink "$ENV{'PBTMP'}/$f";
	pb_system("$vcscmd $ENV{'PBTMP'}/$f $uri","Downloading $uri with $vcscmd to $ENV{'PBTMP'}/$f\n");
	# We want to preserve the original tar file
	pb_vcs_export("file://$ENV{'PBTMP'}/$f",$source,$destdir);
	return("$ENV{'PBTMP'}/$f");
} elsif ($scheme =~ /^file/) {
	eval
	{
		require File::MimeInfo;
		File::MimeInfo->import();
	};
	if ($@) {
		# File::MimeInfo not found
		confess("ERROR: Install File::MimeInfo to handle scheme $scheme\n");
	}

	my $mm = mimetype($path);
	pb_log(2,"mimetype: $mm\n");

	# Check whether the file is well formed 
	# (containing already a directory with the project-version name)
	#
	# If it's not the case, we try to adapt, but distro needing 
	# to verify the checksum will have issues (Fedora)
	# Then upstream should be notified that they need to change their rules
	# This doesn't apply to patches or additional sources of course.
	my ($pbwf) = pb_conf_get_if("pbwf");
	if ((defined $pbwf) && (defined $pbwf->{$ENV{'PBPROJ'}}) && ($path !~ /\/pbpatch\//) && ($path !~ /\/pbsrc\//)) {
		$destdir = dirname($destdir);
		pb_log(2,"This is a well-formed file so destdir is now $destdir\n");
	}
	pb_mkdir_p($destdir);

	if ($mm =~ /\/x-bzip-compressed-tar$/) {
		# tar+bzip2
		pb_system("cd $destdir ; tar xfj $path","Extracting $path in $destdir ");
	} elsif ($mm =~ /\/x-lzma-compressed-tar$/) {
		# tar+lzma
		pb_system("cd $destdir ; tar xfY $path","Extracting $path in $destdir ");
	} elsif ($mm =~ /\/x-compressed-tar$/) {
		# tar+gzip
		pb_system("cd $destdir ; tar xfz $path","Extracting $path in $destdir ");
	} elsif ($mm =~ /\/x-tar$/) {
		# tar
		pb_system("cd $destdir ; tar xf $path","Extracting $path in $destdir ");
	} elsif ($mm =~ /\/zip$/) {
		# zip
		pb_system("cd $destdir ; unzip $path","Extracting $path in $destdir ");
	} else {
		# simple file: copy it (patch e.g.)
		copy($path,$destdir);
	}
} elsif ($scheme =~ /^hg/) {
	if (defined $source) {
		if (-d $source) {
			$tmp = $destdir;
		} else {
			$tmp = "$destdir/".basename($source);
		}
		$source = pb_vcs_mod_htftp($source,"hg");
		pb_system("cd $source ; $vcscmd archive $tmp","Exporting $source from Mercurial to $tmp ");
	} else {
		$uri = pb_vcs_mod_htftp($uri,"hg");
		pb_system("$vcscmd clone $uri $destdir","Exporting $uri from Mercurial to $destdir ");
	}
} elsif ($scheme =~ /^git/) {
	if ($scheme =~ /svn/) {
		if (defined $source) {
			if (-d $source) {
				$tmp = $destdir;
			} else {
				$tmp = "$destdir/".basename($source);
			}
			$source = pb_vcs_mod_htftp($source,"git");
			pb_system("cp -a $source $tmp","Exporting $source from $scheme to $tmp ");
		} else {
			$uri = pb_vcs_mod_htftp($uri,"git");
			pb_system("$vcscmd clone $uri $destdir","Exporting $uri from $scheme to $destdir ");
		}
	} else {
		if (defined $source) {
			if (-d $source) {
				$tmp = $destdir;
			} else {
				$tmp = "$destdir/".basename($source);
			}
			$source = pb_vcs_mod_htftp($source,"git");
			my ($pbpbr) = pb_conf_get_if("pbpbr");
			if ((defined $pbpbr) && (defined $pbpbr->{$ENV{'PBPROJ'}})) {
				# The project uses pbr so benefit from it to export data
				pb_system("cd $source ; mkdir $tmp ; python setup.py sdist --keep-temp --dist-dir $tmp ; cd $tmp ; file=`ls *.tar.gz` ;  if [ _\$file = _ ] || [ ! -f \$file ]; then exit -1; fi; tar xfz \$file ; dir=`tar tvfz \$file | head -1 | awk '{print \$6}'` ; if [ ! -d \$dir ] || [ _\$dir = _ ] || [ \$dir = / ]; then exit -1 ; fi ; mv \$dir/* \$dir/.??* . ; rmdir \$dir ; rm -f \$file ; ls -al ","Exporting current $source from GIT with pbr to $tmp ");
			} else {
				# no pbr do it ourselves
				pb_system("cd $source ; stid=`$vcscmd stash create` ; $vcscmd archive --format=tar \$\{stid:=HEAD\} | (mkdir $tmp && cd $tmp && tar xf -)","Exporting current $source from GIT to $tmp ");
			}
		} else {
			$uri = pb_vcs_mod_htftp($uri,"git");
			pb_system("$vcscmd clone $uri $destdir","Exporting $uri from GIT to $destdir ");
		}
	}
} elsif ($scheme =~ /^cvs/) {
	# CVS needs a relative path !
	my $dir=dirname($destdir);
	my $base=basename($destdir);
	if (defined $source) {
		# CVS also needs a modules name not a dir
		$tmp1 = basename($source);
	} else {
		# Probably not right, should be checked, but that way I'll notice it :-)
		pb_log(0,"You're in an untested part of project-builder.org, please report any result upstream\n");
		$tmp1 = $uri;
	}
	# If we're working on the CVS itself
	my $cvstag = basename($ENV{'PBROOTDIR'});
	my $cvsopt = "";
	if ($cvstag eq "cvs") {
		my $pbdate = strftime("%Y-%m-%d %H:%M:%S", @date);
		$cvsopt = "-D \"$pbdate\"";
	} else {
		# we're working on a tag which should be the last part of PBROOTDIR
		$cvsopt = "-r $cvstag";
	}
	pb_system("cd $dir ; $vcscmd -d $account\@$host:$path export $cvsopt -d $base $tmp1","Exporting $tmp1 from $source under CVS to $destdir ");
} else {
	confess "cms $scheme unknown";
}
return(undef);
}

=item B<pb_vcs_get_uri>

This function is only called with a real VCS system and gives the URL stored in the checked out directory.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the directory in which it is locally exposed (result of a checkout).

=cut

sub pb_vcs_get_uri {

my $scheme = shift;
my $dir = shift;

my $res = "";
my $void = "";
my $vcscmd = pb_vcs_cmd($scheme);

if ($scheme =~ /^svn/) {
	open(PIPE,"LANGUAGE=C $vcscmd info $dir 2> /dev/null |") || return("");
	while (<PIPE>) {
		($void,$res) = split(/^URL:/) if (/^URL:/);
	}
	$res =~ s/^\s*//;
	close(PIPE);
	chomp($res);
} elsif ($scheme =~ /^svk/) {
	open(PIPE,"LANGUAGE=C $vcscmd info $dir 2> /dev/null |") || return("");
	my $void2 = "";
	while (<PIPE>) {
		($void,$void2,$res) = split(/ /) if (/^Depot/);
	}
	$res =~ s/^\s*//;
	close(PIPE);
	chomp($res);
} elsif ($scheme =~ /^hg/) {
	open(HGRC,".hg/hgrc/") || return("");
	while (<HGRC>) {
		($void,$res) = split(/^default.*=/) if (/^default.*=/);
	}
	close(HGRC);
	chomp($res);
} elsif ($scheme =~ /^git/) {
	if ($scheme =~ /svn/) {
		my $cwd = abs_path();
		chdir($dir) || return("");;
		open(PIPE,"LANGUAGE=C $vcscmd info . 2> /dev/null |") || return("");
		chdir($cwd) || return("");
		while (<PIPE>) {
			($void,$res) = split(/^URL:/) if (/^URL:/);
		}
		$res =~ s/^\s*//;
		close(PIPE);
		chomp($res);
		# We've got an SVN ref so add git in front of it for coherency
		$res = "git+".$res;
	} else {
		# Pure git
		# First we may deal with a separate git repo under $dir
		if ( -d "$dir/.git" ) {
			open(GIT,"LANGUAGE=C $vcscmd --git-dir=$dir/.git remote -v 2> /dev/null |") || return("");
		} else {
			# If not, the pbconf dir may be in the pbprojdir so sharing the .git dir
			my $cwd = abs_path();
			chdir($dir) || return("");;
			open(GIT,"LANGUAGE=C $vcscmd remote -v 2> /dev/null |") || return("");
			chdir($cwd) || return("");
		}
		while (<GIT>) {
			next unless (/^origin\s+(\S+) \(push\)$/);
			return $1;
		}
		close(GIT);
		warn "Unable to find remote origin for $dir";
		return "";
	}
} elsif ($scheme =~ /^cvs/) {
	# This path is always the root path of CVS, but we may be below
	open(FILE,"$dir/CVS/Root") || confess "$dir isn't CVS controlled";
	$res = <FILE>;
	chomp($res);
	close(FILE);
	# Find where we are in the tree
	my $rdir = $dir;
	while ((! -d "$rdir/CVSROOT") && ($rdir ne "/")) {
		$rdir = dirname($rdir);
	}
	confess "Unable to find a CVSROOT dir in the parents of $dir" if (! -d "$rdir/CVSROOT");
	#compute our place under that root dir - should be a relative path
	$dir =~ s|^$rdir||;
	my $suffix = "";
	$suffix = "$dir" if ($dir ne "");

	my $prefix = "";
	if ($scheme =~ /ssh/) {
		$prefix = "cvs+ssh://";
	} else {
		$prefix = "cvs://";
	}
	$res = $prefix.$res.$suffix;
} else {
	confess "cms $scheme unknown";
}
pb_log(1,"pb_vcs_get_uri returns $res\n");
return($res);
}

=item B<pb_vcs_copy>

This function copies a VCS content to another.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the URL of the original VCS content.
The third parameter is the URL of the destination VCS content.

Only coded for SVN now as used for pbconf itself not the project

=cut

sub pb_vcs_copy {
my $scheme = shift;
my $oldurl = shift;
my $newurl = shift;
my $vcscmd = pb_vcs_cmd($scheme);
$oldurl = pb_vcs_mod_socks($oldurl);
$newurl = pb_vcs_mod_socks($newurl);

if ($scheme =~ /^svn/) {
	$oldurl = pb_vcs_mod_htftp($oldurl,"svn");
	$newurl = pb_vcs_mod_htftp($newurl,"svn");
	pb_system("$vcscmd copy -m \"Creation of $newurl from $oldurl\" $oldurl $newurl","Copying $oldurl to $newurl ");
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	# Nothing to do.
} else {
	confess "cms $scheme unknown for project management";
}
}

=item B<pb_vcs_checkout>

This function checks a VCS content out to a directory.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the URL of the VCS content.
The third parameter is the directory where we want to deliver it (result of export).

=cut

sub pb_vcs_checkout {
my $scheme = shift;
my $url = shift;
my $destination = shift;
my $vcscmd = pb_vcs_cmd($scheme);
$url = pb_vcs_mod_socks($url);

if ($scheme =~ /^svn/) {
	$url = pb_vcs_mod_htftp($url,"svn");
	pb_system("$vcscmd co $url $destination","Checking out $url to $destination ");
} elsif ($scheme =~ /^svk/) {
	$url = pb_vcs_mod_htftp($url,"svk");
	pb_system("$vcscmd co $url $destination","Checking out $url to $destination ");
} elsif ($scheme =~ /^hg/) {
	$url = pb_vcs_mod_htftp($url,"hg");
	pb_system("$vcscmd clone $url $destination","Checking out $url to $destination ");
} elsif ($scheme =~ /^git/) {
	$url = pb_vcs_mod_htftp($url,"git");
	pb_system("$vcscmd clone $url $destination","Checking out $url to $destination ");
} elsif (($scheme eq "ftp") || ($scheme eq "http")) {
	return;
} elsif ($scheme =~ /^cvs/) {
	my ($scheme, $account, $host, $port, $path) = pb_get_uri($url);

	# If we're working on the CVS itself
	my $cvstag = basename($ENV{'PBROOTDIR'});
	my $cvsopt = "";
	if ($cvstag eq "cvs") {
		my @date = pb_get_date();
		my $pbdate = strftime("%Y-%m-%d %H:%M:%S", @date);
		$cvsopt = "-D \"$pbdate\"";
	} else {
		# we're working on a tag which should be the last part of PBROOTDIR
		$cvsopt = "-r $cvstag";
	}
	pb_mkdir_p("$destination");
	pb_system("cd $destination ; $vcscmd -d $account\@$host:$path co $cvsopt .","Checking out $url to $destination ");
} elsif ($scheme =~ /^file/) {
	pb_vcs_export($url,undef,$destination);
} else {
	confess "cms $scheme unknown";
}
}

=item B<pb_vcs_up>

This function updates a local directory with the VCS content.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the list of directory to update.

=cut

sub pb_vcs_up {
my $scheme = shift;
my @dir = @_;
my $vcscmd = pb_vcs_cmd($scheme);

if ($scheme =~ /^((svn)|(cvs)|(svk))/o) {
	pb_system("$vcscmd up ".join(' ',@dir),"Updating ".join(' ',@dir));
} elsif ($scheme =~ /^((hg)|(git))/o) {
	foreach my $d (@dir) {
		pb_system("(cd $d && $vcscmd fetch)", "Updating $d ");
	}
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	# Nothing to do.
} else {
	confess "cms $scheme unknown";
}
}

=item B<pb_vcs_checkin>

This function updates a VCS content from a local directory.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the directory to update from.
The third parameter is the comment to pass during the commit

=cut

sub pb_vcs_checkin {
my $scheme = shift;
my $dir = shift;
my $msg = shift;
my $vcscmd = pb_vcs_cmd($scheme);

if ($scheme =~ /^((svn)|(cvs)|(svk))/o) {
	pb_system("cd $dir && $vcscmd ci -m \"$msg\" .","Checking in $dir ");
} elsif ($scheme =~ /^git/) {
	pb_system("cd $dir && $vcscmd commit -a -m \"$msg\"", "Checking in $dir ");
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	# Nothing to do.
} else {
	confess "cms $scheme unknown";
}
pb_vcs_up($scheme,$dir);
}

=item B<pb_vcs_add_if_not_in>

This function adds to a VCS content from a local directory if the content wasn't already managed under th VCS.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is a list of directory/file to add.

=cut

sub pb_vcs_add_if_not_in {
my $scheme = shift;
my @f = @_;
my $vcscmd = pb_vcs_cmd($scheme);

if ($scheme =~ /^((hg)|(git)|(svn)|(svk)|(cvs))/o) {
	for my $f (@f) {
		my $uri = pb_vcs_get_uri($scheme,$f);
		pb_vcs_add($scheme,$f) if ($uri !~ /^$scheme/);
	}
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	# Nothing to do.
} else {
	confess "cms $scheme unknown";
}
}

=item B<pb_vcs_add>

This function adds to a VCS content from a local directory.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is a list of directory/file to add.

=cut

sub pb_vcs_add {
my $scheme = shift;
my @f = @_;
my $vcscmd = pb_vcs_cmd($scheme);

if ($scheme =~ /^((hg)|(git)|(svn)|(svk)|(cvs))/o) {
	pb_system("$vcscmd add ".join(' ',@f),"Adding ".join(' ',@f)." to VCS ");
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	# Nothing to do.
} else {
	confess "cms $scheme unknown";
}
pb_vcs_up($scheme,@f);
}

=item B<pb_vcs_isdiff>

This function returns a integer indicating the number of differences between the VCS content and the local directory where it's checked out.
The first parameter is the schema of the VCS systems (svn, cvs, svn+ssh, ...)
The second parameter is the directory to consider.

=cut

sub pb_vcs_isdiff {
my $scheme = shift;
my $dir =shift;
my $vcscmd = pb_vcs_cmd($scheme);
my $l = undef;

if ($scheme =~ /^((svn)|(cvs)|(svk)|(git))/o) {
	open(PIPE,"$vcscmd diff $dir |") || confess "Unable to get $vcscmd diff from $dir";
	$l = 0;
	while (<PIPE>) {
		# Skipping normal messages in case of CVS
		next if (/^cvs diff:/);
		$l++;
	}
} elsif ($scheme =~ /^(flat)|(ftp)|(http)|(file)\b/o) {
	$l = 0;
} else {
	confess "cms $scheme unknown";
}
pb_log(1,"pb_vcs_isdiff returns $l\n");
return($l);
}

sub pb_vcs_mod_htftp {

my $url = shift;
my $proto = shift;

$url =~ s/^$proto\+((ht|f)tp[s]*):/$1:/;
pb_log(1,"pb_vcs_mod_htftp returns $url\n");
return($url);
}

sub pb_vcs_mod_socks {

my $url = shift;

$url =~ s/^([A-z0-9]+)\+(socks):/$1:/;
pb_log(1,"pb_vcs_mod_socks returns $url\n");
return($url);
}


sub pb_vcs_cmd {

my $scheme = shift;
my $cmd = "";
my $cmdopt = "";

# If there is a socks proxy to use
if ($scheme =~ /socks/) {
	# Get the socks proxy command from the conf file
	my ($pbsockscmd) = pb_conf_get("pbsockscmd");
	$cmd = "$pbsockscmd->{$ENV{'PBPROJ'}} ";
}

if (defined $ENV{'PBVCSOPT'}) {
	$cmdopt .= " $ENV{'PBVCSOPT'}";
}

if ($scheme =~ /hg/) {
	$cmd .= "hg".$cmdopt;
} elsif ($scheme =~ /git/) {
	if ($scheme =~ /svn/) {
		$cmd .= "git svn".$cmdopt;
	} else {
		$cmd .= "git".$cmdopt;
	}
} elsif ($scheme =~ /svn/) {
	$cmd .= "svn".$cmdopt;
} elsif ($scheme =~ /svk/) {
	$cmd .= "svk".$cmdopt;
} elsif ($scheme =~ /cvs/) {
	$cmd .= "cvs".$cmdopt;
} elsif (($scheme =~ /http/) || ($scheme =~ /ftp/)) {
	my $command = pb_check_req("wget",1);
	if (-x $command) {
		$cmd .= "$command -nv -O ";
	} else {
		$command = pb_check_req("curl",1);
		if (-x $command) {
			$cmd .= "$command -o ";
		} else {
			confess "Unable to handle $scheme.\nNo wget/curl available, please install one of those";
		}
	}
} else {
	$cmd = "";
}
pb_log(3,"pb_vcs_cmd returns $cmd\n");
return($cmd);
}

=item B<pb_vcs_compliant>

This function checks the compliance of the project and the pbconf directory.
The first parameter is the key name of the value that needs to be read in the configuration file.
The second parameter is the environment variable this key will populate.
The third parameter is the location of the pbconf dir.
The fourth parameter is the URI of the CMS content related to the pbconf dir.
The fifth parameter indicates whether we should inititate the context or not.

=cut

sub pb_vcs_compliant {

my $param = shift;
my $envar = shift;
my $defdir = shift;
my $uri = shift;
my $pbinit = shift;
my %pdir;

pb_log(1,"pb_vcs_compliant: envar: $envar - defdir: $defdir - uri: $uri\n");
my ($pdir) = pb_conf_get_if($param) if (defined $param);
if (defined $pdir) {
	%pdir = %$pdir;
}

if ((defined $pdir) && (%pdir) && (defined $pdir{$ENV{'PBPROJ'}})) {
	# That's always the environment variable that will be used
	$ENV{$envar} = $pdir{$ENV{'PBPROJ'}};
} else {
	if (defined $param) {
		pb_log(1,"WARNING: no $param defined, using $defdir\n");
		pb_log(1,"         Please create a $param reference for project $ENV{'PBPROJ'} in $ENV{'PBETC'}\n");
		pb_log(1,"         if you want to use another directory\n");
	}
	$ENV{$envar} = "$defdir";
}

# Expand potential env variable in it
eval { $ENV{$envar} =~ s/(\$ENV.+\})/$1/eeg };
pb_log(2,"$envar: $ENV{$envar}\n");

my ($scheme, $account, $host, $port, $path) = pb_get_uri($uri);

if (($scheme !~ /^cvs/) && ($scheme !~ /^svn/) && ($scheme !~ /^svk/) && ($scheme !~ /^hg/) && ($scheme !~ /^git/)) {
	# Do not compare if it's not a real cms
	pb_log(1,"pb_vcs_compliant useless\n");
	return;
} elsif (defined $pbinit) {
	pb_mkdir_p("$ENV{$envar}");
} elsif (! -d "$ENV{$envar}") {
	# Either we have a version in the uri, and it should be the same
	# as the one in the envar. Or we should add the version to the uri
	# But not if it's git as it manages version branches internally
	if ((basename($uri) ne basename($ENV{$envar})) && ($scheme !~ /^git/)) {
		$uri .= "/".basename($ENV{$envar})
	}
	pb_log(1,"Checking out $uri\n");
	# Create structure and remove end dir before exporting
	pb_mkdir_p("$ENV{$envar}");
	pb_rm_rf($ENV{$envar});
	pb_vcs_checkout($scheme,$uri,$ENV{$envar});
} else {
	pb_log(1,"$uri found locally, checking content\n");
	my $cmsurl = pb_vcs_get_uri($scheme,$ENV{$envar});
	my ($scheme2, $account2, $host2, $port2, $path2) = pb_get_uri($cmsurl);
	# For svk, scheme doesn't appear in svk info so remove it here in uri coming from conf file 
	# which needs it to trigger correct behaviour
	$uri =~ s/^svk://;
	if ($scheme2 =~ /^git/) {
		# remove schema from `git+file:` and `git+dir:` urls
		# TODO: handle query-parameters
		$uri =~ s/^git\+(file|dir|ssh):[\/]*//;
		# Expand potential env variable in it -- this is required due to the consistency check
		$uri =~ s/(\$ENV.+\})/$1/eeg;
	} elsif ($scheme2 =~ /^hg/) {
		# This VCS manages branches internally not with different tree structures
		# Assuming it's correct for now.
		return;
	}
	# Remove git+ part if only in scheme
	$uri =~ s/^git\+// if (($scheme =~ /^git\+/) && ($scheme2 !~ /^git\+/));

	if ($cmsurl ne $uri) {
		# The local content doesn't correpond to the repository
		pb_log(0,"ERROR: Inconsistency detected:\n");
		pb_log(0,"       * $ENV{$envar} ($envar) refers to $cmsurl but\n");
		pb_log(0,"       * $ENV{'PBETC'} refers to $uri\n");
		die "Project $ENV{'PBPROJ'} is not Project-Builder compliant.";
	} else {
		pb_log(1,"Content correct - doing nothing - you may want to update your repository however\n");
		# they match - do nothing - there may be local changes
	}
}
pb_log(1,"pb_vcs_compliant end\n");
}


=back 

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
