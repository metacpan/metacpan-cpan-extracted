use strict;
use warnings;

package PortageXS::Core;
BEGIN {
  $PortageXS::Core::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::Core::VERSION = '0.3.1';
}

# ABSTRACT: Core behaviour role for C<PortageXS>
#
# -----------------------------------------------------------------------------
#
# PortageXS::Core
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS/Core.pm,v 1.19 2008/12/01 19:53:27 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------

use Path::Tiny qw(path);
use Shell::EnvImporter;
use Role::Tiny;


# Description:
# Returnvalue is ARCH set in the system-profile.
# Wrapper for old getArch()-version. Use getPortageMakeParam() instead.
#
# Example:
# $arch=$pxs->getArch();
sub getArch {
	my $self	= shift;
	return $self->getPortageMakeParam('ARCH');
}

# Description:
# Returns the profile tree as array
# "depth ﬁrst, left to right, with duplicate parent paths being sourced
# for every time they are encountered"
sub getProfileTree {
	my $self	= shift;
	my $curPath	= shift;
	my @path;

	my $parent = path("$curPath/parent");
	if ( -e $parent ) {
		foreach my $line ($parent->lines({ chomp => 1 })) {
			push @path, $self->getProfileTree("$curPath/$line");
		}
	}
	push @path, $curPath;
	return @path;
}

# Description:
# Helper for getPortageMakeParam()
sub getPortageMakeParamHelper {
	my $self	= shift;
	my $curPath	= shift;
	my @files	= ();

	foreach my $profile ( $self->getProfileTree($curPath) ) {
		push(@files,"$profile/make.defaults") if (-e "$profile/make.defaults");
	}
	return @files;
}

# Description:
# Returnvalue is $PARAM set in the system-profile.
#
# Example:
# $arch=$pxs->getPortageMakeParam();
sub getPortageMakeParam {
	my $self		= shift;
	my $param		= shift;
	my @files		= ();
	my @etcfiles	= ( $self->{'MAKE_GLOBALS_PATH'}, $self->{'MAKE_CONF_PATH'}) ;
	my $v			= '';
	my $parent		= '';
	my $curPath;

	if(!-e $self->{'MAKE_PROFILE_PATH'}) {
		$self->print_err('Profile not set!');
		exit(0);
	}
	else {
		$curPath=$self->getProfilePath();
	}

	@files=$self->getPortageMakeParamHelper($curPath);
	push(@files,@etcfiles);

	foreach (@files) {
		my $importer = Shell::EnvImporter->new(	shell		=> "bash",
							file		=> $_,
							auto_run	=> 1,
							auto_import	=> 1
					);

		$importer->shellobj->envcmd('set');
		$importer->run();

		if ($ENV{$param}) {
			$v=$ENV{$param};
			$v=~s/\\t/ /g;
			$v=~s/\t/ /g;
			$v=~s/^\$'(.*)'$/$1/m;
			$v=~s/^'(.*)'$/$1/m;
			$v=~s/\\n/ /g;
			$v=~s/\\|\'|\\'|\$//gmxs;
			$v=~s/^\s//;
			$v=~s/\s$//;
			$v=~s/\s{2,}/ /g;
		}

		$importer->restore_env();
	}

	# - Defaults >
	if ($param eq 'PORTDIR' && !$v) {
		$v= $self->{PREFIX}->child('usr/portage');
	}

	return $v;
}

# Description:
# Returnvalue is PORTDIR from make.conf or make.globals (make.conf overrules make.globals).
# This function initializes itself at the first time it is called and reuses $self->{'PORTDIR'}
# as a return value from then on.
#
# Provides:
# $self->{'PORTDIR'}
#
# Parameters:
# $forcereload is optional and forces a reload of the make.conf and make.globals files.
#
# Example:
# $portdir=$pxs->getPortdir([$forcereload]);
sub getPortdir {
    die "please use pxs->portdir";
}

# Description:
# Returnvalue is PORTDIR_OVERLAY from make.conf or make.globals (make.conf overrules make.globals).
#
# Parameters:
# $forcereload is optional and forces a reload of the make.conf and make.globals files.
#
# Example:
# @portdir_overlay=$pxs->getPortdirOverlay();
sub getPortdirOverlay {
	my $self	= shift;
	my $forcereload	= shift;

    return split(/ /, $self->config->getParam('PORTDIR_OVERLAY', 'lastseen'));
}

# Description:
# Returnvalue is the content of the given file.
# $filecontent=$pxs->getFileContents($file);
sub getFileContents {
    die 'getFileContents(foo) is deprecated, use Path::Tiny; path(foo)->slurp';
}

# Description:
# Returns an array containing all packages that match $searchString
# @packages=$pxs->searchInstalledPackage($searchString);
sub searchInstalledPackage {
	my $self		= shift;
	my $searchString	= shift; if (! $searchString) { $searchString=''; }
	my @matches		= ();
	my $s_cat		= '';
	my $s_pak		= '';
	my $m_cat		= 0;

	# - escape special chars >
	$searchString =~ s/\+/\\\+/g;

	# - split >
	if ($searchString=~m/\//) {
		($s_cat,$s_pak)=split(/\//,$searchString);
	}
	else {
		$s_pak=$searchString;
	}

	$s_cat=~s/\*//g;
	$s_pak=~s/\*//g;

	# - read categories >
	my $dhc = path($self->{'PKG_DB_DIR'})->iterator;
	if (defined $dhc) {
		while (defined(my $tc = $dhc->())) {
			$m_cat=0;
			if ($s_cat ne '') {
				if ($tc->basename=~m/$s_cat/i) {
					$m_cat=1;
				}
				else {
					next;
				}
			}

			# - not excluded and $_ is a dir?
			if (! $self->{'EXCLUDE_DIRS'}{$tc->basename} && -d $tc) {
				my $dhp = $tc->iterator;
				while (defined(my $tp = $dhp->())) {
					# - check if packagename matches
					#   (faster if we already check it now) >
					if ($tp->basename =~m/$s_pak/i || $s_pak eq '') {
						# - not excluded and $_ is a dir?
						if (! $self->{'EXCLUDE_DIRS'}{$tp->basename} && -d $tp) {
							if (($s_cat ne '') && ($m_cat)) {
								push(@matches,$tc->basename.'/'.$tp->basename);
							}
							elsif ($s_cat eq '') {
								push(@matches,$tc->basename.'/'.$tp->basename);
							}
						}
					}
				}
				undef $dhp;
			}
		}
	}
	undef $dhc;

	return (sort @matches);
}

sub _foreach_category {
	my ( $self, $repo , $callback ) = @_;
	return () unless -d $repo;
	for my $category ($self->getCategories($repo)) {
        my $path =    $repo . '/' . $category;
        if ( not -e $path ){
            die "Category $path expected, but does not exist";
        }
        if ( not -d $path ){
            die "Category $path exists, but is not a dir";
        }
        if ( not -r $path ){
            warn "Category $path exists, but not readable, skipping";
            next;
        }
		local $_ = {
			category => $category,
			path     => $path
		};
   		my $result = $callback->();
		return if defined $result and $result eq 'BAIL';
	}
}
sub _foreach_package {
	my ( $self, $repo, $category, $callback ) = @_;
	return () unless -d $repo;
	my $category_path = $repo . '/' . $category;
	return () unless -d $category_path;
	return () unless -r $category_path;
	my $dhc = path( $category_path )->iterator;
	while(defined(my $tp = $dhc->()) ){
		next if $self->{'EXCLUDE_DIRS'}{$tp->basename};
		local $_ = {
			category => $category,
			package  => $tp->basename,
			path     => $tp
		};
		my $result = $callback->();
		return if defined $result and $result eq 'BAIL';
	}
}

sub _searchPackage_like {
	my ( $self, $searchString, $repo ) = @_ ;
	return () unless -d $repo;
	$searchString =~ s/\+/\\\+/g;
	my @matches;
	# - read categories >
	$self->_foreach_category( $repo => sub {
		$self->_foreach_package( $repo =>  $_->{category} => sub {
			return unless $_->{package} =~ m/$searchString/i;
			return unless -d $_->{path};
			push @matches, $_->{category} . '/' . $_->{package};
		});
	});
	return (sort @matches);
}

sub _searchPackage_exact {
	my ( $self, $searchString, $repo ) = @_ ;
	return () unless -d $repo;
	my @matches;
	# - read categories >
	$self->_foreach_category( $repo => sub {
		$self->_foreach_package( $repo =>  $_->{category} => sub {
			return unless $_->{package} eq $searchString;
			return unless -d $_->{path};
			push @matches, $_->{category} . '/' . $_->{package};
		});
	});
	return (sort @matches);
}

# Description:
# Search for packages in given repository.
# @packages=$pxs->searchPackage($searchString [,$mode, $repo] );
#
# Parameters:
# searchString: string to search for
# mode: like || exact
# repo: repository to search in
#
# Examples:
# @packages=$pxs->searchPackage('perl');
# @packages=$pxs->searchPackage('perl','exact');
# @packages=$pxs->searchPackage('perl','like','/usr/portage');
# @packages=$pxs->searchPackage('git','exact','/usr/local/portage');
sub searchPackage {
	my $self		= shift;
	my $searchString	= shift;
	my $mode		= shift;
	my $repo		= shift;
	my @matches		= ();

	if (!$mode) { $mode='like'; }
	$repo=$self->portdir if (!$repo);
	if (!-d $repo) { return (); }

	if ($mode eq 'like') {
		return $self->_searchPackage_like($searchString, $repo );
	}
	if ($mode eq 'exact') {
		return $self->_searchPackage_exact($searchString, $repo );
	}
	die "Unknown search mode $mode";
}

# Description:
# Returns the value of $param. Expects filecontents in $file.
# $valueOfKey=$pxs->getParamFromFile($filecontents,$key,{firstseen,lastseen});
# e.g.
# $valueOfKey=$pxs->getParamFromFile($pxs->getFileContents("/path/to.ebuild"),"IUSE","firstseen");
sub getParamFromFile {
	my $self	= shift;
	my $file	= shift;
	my $param	= shift;
	my $mode	= shift; # ("firstseen","lastseen") - default is "lastseen"
	my $c		= 0;
	my $d		= 0;
	my @lines	= ();
	my $value	= ''; # value of $param

	# - split file in lines >
	@lines = split(/\n/,$file);

	for($c=0;$c<=$#lines;$c++) {
		next if $lines[$c]=~m/^#/;

		# - remove comments >
		$lines[$c]=~s/#(.*)//g;

		# - remove leading whitespaces and tabs >
		$lines[$c]=~s/^[ \t]+//;

		if ($lines[$c]=~/^$param="(.*)"/) {
			# single-line with quotationmarks >
			$value=$1;

			last if ($mode eq 'firstseen');
		}
		elsif ($lines[$c]=~/^$param="(.*)/) {
			# multi-line with quotationmarks >
			$value=$1.' ';
			for($d=$c+1;$d<=$#lines;$d++) {
				# - look for quotationmark >
				if ($lines[$d]=~/(.*)"?/) {
					# - found quotationmark; append contents and leave loop >
					$value.=$1;
					last;
				}
				else {
					# - no quotationmark found; append line contents to $value >
					$value.=$lines[$d].' ';
				}
			}

			last if ($mode eq 'firstseen');
		}
		elsif ($lines[$c]=~/^$param=(.*)/) {
			# - single-line without quotationmarks >
			$value=$1;

			last if ($mode eq 'firstseen');
		}
	}

	# - clean up value >
	$value=~s/^[ \t]+//; # remove leading whitespaces and tabs
	$value=~s/[ \t]+$//; # remove trailing whitespaces and tabs
	$value=~s/\t/ /g;     # replace tabs with whitespaces
	$value=~s/ {2,}/ /g;  # replace 1+ whitespaces with 1 whitespace

	return $value;
}

# Description:
# Returns useflag settings of the given (installed) package.
# @useflags=$pxs->getUseSettingsOfInstalledPackage("dev-perl/perl-5.8.8-r3");
sub getUseSettingsOfInstalledPackage {
	my $self		= shift;
	my $package		= shift;
	my $tmp_filecontents	= '';
	my @package_IUSE	= ();
	my @package_USE		= ();
	my @USEs		= ();
	my $hasuse		= '';

	my $IUSE_PATH = path($self->{PKG_DB_DIR} )->child($package, 'IUSE');
	my $USE_PATH  = path($self->{PKG_DB_DIR} )->child($package, 'USE' );

	if (-e $IUSE_PATH ) {
		$tmp_filecontents	= $IUSE_PATH->slurp;
	}
	$tmp_filecontents	=~s/\n//g;
	@package_IUSE		= split(/ /,$tmp_filecontents);
	if (-e $USE_PATH ) {
		$tmp_filecontents	= $USE_PATH->slurp;
	}
	$tmp_filecontents	=~s/\n//g;
	@package_USE		= split(/ /,$tmp_filecontents);

	foreach my $thisIUSE (@package_IUSE) {
		next if ($thisIUSE eq '');
		$hasuse = '-';
		foreach my $thisUSE (@package_USE) {
			if ($thisIUSE eq $thisUSE) {
				$hasuse='';
				last;
			}
		}
		push(@USEs,$hasuse.$thisIUSE);
	}

	return @USEs;
}

# Description:
# @listOfEbuilds=$pxs->getAvailableEbuilds(category/packagename,[$repo]);
sub getAvailableEbuilds {
	my $self	= shift;
	my $catPackage	= shift;
	my $repo	= shift;
	my @packagelist	= ();

	$repo=$self->portdir if (!$repo);
	if (!-d $repo) { return (); }

	my $repo_path = path($repo);
	my $category = $repo_path->child( $catPackage );

	if (-e $category) {
		# - get list of ebuilds >
		my $dh = $category->iterator();
		while (defined(my $ebuild = $dh->())) {
			if ($ebuild->basename =~ m/(.+)\.ebuild$/) {
				push(@packagelist,$ebuild);
			}
		}
	}

	return @packagelist;
}

# Description:
# @listOfEbuildVersions=$pxs->getAvailableEbuildVersions(category/packagename,[$repo]);
sub getAvailableEbuildVersions {
	my $self	= shift;
	my $catPackage	= shift;
	my $repo	= shift;
	my @packagelist;

	@packagelist = map { $self->getEbuildVersion($_) } $self->getAvailableEbuilds($catPackage,$repo);

	return @packagelist;
}

# Description:
# $bestVersion=$pxs->getBestEbuildVersion(category/packagename,[$repo]);
sub getBestEbuildVersion {
	my $self	= shift;
	my $catPackage	= shift;
	my $repo	= shift;

	my @versions = map { PortageXS::Version->new($_) } $self->getAvailableEbuildVersions($catPackage,$repo);
	my @best_version = sort { $a <=> $b } (@versions);
	return $best_version[-1];
}

# Description:
# @listOfArches=$pxs->getAvailableArches();
sub getAvailableArches {
	my $self	= shift;
	return $self->portdir->child('profiles','arch.list')->lines({ chomp => 1 });
}

# Description:
# Reads from /etc/portagexs/categories/$listname.list and returns all entries as an array.
# @listOfCategories=$pxs->getPortageXScategorylist($listname);
sub getPortageXScategorylist {
	my $self	= shift;
	my $category	= shift;
	my $etcpath = path($self->{'PORTAGEXS_ETC_DIR'});
	return $etcpath->child('categories',$category . '.list')->lines({ chomp => 1 });
}

# Description:
# Returns all available packages from the given category.
# @listOfPackages=$pxs->getPackagesFromCategory($category,[$repo]);
# E.g.:
# @listOfPackages=$pxs->getPackagesFromCategory("dev-perl","/usr/portage");
sub getPackagesFromCategory {
	my $self	= shift;
	my $category	= shift;
	my $repo	= shift;
	my @packages	= ();

	return () if !$category;
	$repo= $self->portdir if (!$repo);

	my $repo_path = path($repo);
	my $category_path = $repo_path->child( $category );

	if (-d $category_path ) {
		my $dhp = $category_path->iterator;
		while (defined( my $tp = $dhp->())) {
			# - not excluded and $_ is a dir?
			if (! $self->{'EXCLUDE_DIRS'}{$tp->basename} && -d $tp) {
				push(@packages,$tp);
			}
		}
		undef $dhp;
	}

	return @packages;
}

# Description:
# Returns package(s) where $file belongs to.
# (Actually this is an array and not a scalar due to a portage design bug.)
# @listOfPackages=$pxs->fileBelongsToPackage("/path/to/file");
sub fileBelongsToPackage {
	my $self	= shift;
	my $file	= shift;

	my @matches	= ();

	# - read categories >
	my $dhc = path( $self->{'PKG_DB_DIR'} )->iterator;
	if (defined $dhc) {
		while (defined(my $tc = $dhc->())) {
			# - not excluded and $_ is a dir?
			if (! $self->{EXCLUDE_DIRS}{$tc->basename} && -d $tc) {
				my $dhp = $tc->iterator;
				while (defined(my $tp = $dhp->())) {
					my $contents = $tp->child('CONTENTS');
					next unless -f $contents;
				    my $fh = $contents->openr;
					while (<$fh>) {
						if ($_=~m/$file/) {
							push(@matches,$tc->basename.'/'.$tp->basename);
							last;
						}
					}
					close $fh;
				}
			}
		}
	}

	return @matches;
}

# Description:
# Returns all files provided by $category/$package.
# @listOfFiles=$pxs->getFilesOfInstalledPackage("$category/$package");
sub getFilesOfInstalledPackage {
	my $self	= shift;
	my $package	= shift;
	my @files	= ();

	# - find installed versions & loop >
	foreach my $pkg ($self->searchInstalledPackage($package)) {
		my $pkg = ( ref $pkg ? $pkg : do {
			path($self->{PKG_DB_DIR})->child($pkg);
		});
		foreach my $file_line ( $pkg->child('CONTENTS')->lines({ chomp => 1 } )) {
			push(@files,(split(/ /,$file_line))[1]);
		}
	}

	return @files;
}

# Description:
# Returns version of an ebuild.
# $version=$pxs->getEbuildVersion("foo-1.23-r1.ebuild");
sub getEbuildVersion {
	my $self	= shift;
	my $version	= shift;
	$version =~ s/\.ebuild$//;
	$version =~ s/^([a-zA-Z0-9\-_\/\+]*)-([0-9\.]+[a-zA-Z]?)/$2/;

	return $version;
}

# Description:
# Returns name of an ebuild (w/o version).
# $version=$pxs->getEbuildName("foo-1.23-r1.ebuild");
sub getEbuildName {
	my $self	= shift;
	my $version	= shift;
	my $name	= $version;

	$version =~ s/^([a-zA-Z0-9\-_\/\+]*)-([0-9\.]+[a-zA-Z]?)/$2/;

	return substr($name,0,length($name)-length($version)-1);
}

# Description:
# Returns the repo_name of the given repo.
# $repo_name=$pxs->getReponame($repo);
# Example:
# $repo_name=$pxs->getRepomane("/usr/portage");
sub getReponame {
	my $self	= shift;
	my $repo	= shift;
	my $repo_name	= '';

	my $repofile = path($repo)->child('profiles','repo_name' );
	if (-f $repofile ) {
		$repo_name = $repofile->slurp();
		chomp($repo_name);
		return $repo_name;
	}

	return '';
}

# Description:
# Returns an array of URLs of the given mirror.
# @mirrorURLs=$pxs->resolveMirror($mirror);
# Example:
# @mirrorURLs=$pxs->resolveMirror('cpan');
sub resolveMirror {
	my $self	= shift;
	my $mirror	= shift;
	my $mirrorlist	= $self->portdir->child('profiles/thirdpartymirrors');

	foreach my $q_mirror ($mirrorlist->lines({ chomp => 1 })) {
		my @p=split(/\t/,$q_mirror);
		if ($mirror eq $p[0]) {
			return split(/ /,$p[2]);
		}
	}

	return;
}

# Description:
# Returns list of valid categories (from $repo/profiles/categories)
# @categories=$pxs->getCategories($repo);
# Example:
# @categories=$pxs->getCategories('/usr/portage');
sub getCategories {
	my $self	= shift;
	my $repo	= shift;

	my $categoryfile = path($repo)->child('profiles/categories');
	if (-e $categoryfile) {
		return $categoryfile->lines({ chomp => 1 });
	}
    my %not_a_category = (
        'packages','distfiles','profiles','eclass','licenses','metadata','scripts'
    );

    my @categories;
    my $it = path($repo)->iterator;
	while(defined(my $tc = $it->()) ){
		next if $self->{'EXCLUDE_DIRS'}{$tc->basename};
        next if exists $not_a_category{$tc->basename};
        next if not -d $tc;
        push @categories, $tc->basename;
    }
	return (@categories);
}

# Description:
# Returns path to profile.
# $path=$pxs->getProfilePath();
sub getProfilePath {
	my $self	= shift;

	my $profile_path = path($self->{'MAKE_PROFILE_PATH'});
	my $etcdir       = path($self->{'ETC_DIR'});
	my $rl_target    = readlink($profile_path);

	if (-e $etcdir->child($rl_target)) {
		return $etcdir->child($rl_target)
	}
	elsif (-e $rl_target ) {
		return $rl_target;
	}

	return;
}

# Description:
# Returns all packages that are in the world file.
# @packages=$pxs->getPackagesFromWorld();
sub getPackagesFromWorld {
	my $self	= shift;

	if (-e $self->{'PATH_TO_WORLDFILE'}) {
		return path($self->{'PATH_TO_WORLDFILE'})->lines({ chomp => 1 });
	}

	return ();
}

# Description:
# Records package in world file.
# $pxs->recordPackageInWorld($package);
sub recordPackageInWorld {
	my $self	= shift;
	my $package	= shift;
	my %world	= ();

	# - get packages already recorded in world >
	foreach ($self->getPackagesFromWorld()) {
		$world{$_}=1;
	}

	# - add $package >
	$world{$package}=1;

	# - write world file >
	my $fh = path($self->{'PATH_TO_WORLDFILE'})->openw;
	foreach (keys %world) {
		print $fh $_,"\n";
	}
	close $fh;

	return 1;
}

# Description:
# Removes package from world file.
# $pxs->removePackageFromWorld($package);
sub removePackageFromWorld {
	my $self	= shift;
	my $package	= shift;
	my %world	= ();

	# - get packages already recorded in world >
	foreach ($self->getPackagesFromWorld()) {
		$world{$_}=1;
	}

	# - remove $package >
	$world{$package}=0;

	# - write world file >
	my $fh = path($self->{'PATH_TO_WORLDFILE'})->openw;
	foreach (keys %world) {
		print $fh $_,"\n" if ($world{$_});
	}
	close $fh;

	return 1;
}

# Description:
# Returns path to profile.
# $pxs->resetCaches();
sub resetCaches {
	my $self	= shift;

	# - Console >

	# - System - getHomedir >
	$self->{'CACHE'}{'System'}{'getHomedir'}{'homedir'}=undef;

	# - Useflags - getUsedescs >
	foreach my $k1 (keys %{$self->{'CACHE'}{'Useflags'}{'getUsedescs'}}) {
		$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$k1}{'use.desc'}{'initialized'}=undef;
		foreach my $k2 (keys %{$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$k1}{'use.desc'}{'use'}}) {
			$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$k1}{'use.desc'}{'use'}{$k2}=undef;
		}
		$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$k1}{'use.desc'}{'use'}=undef;
		$self->{'CACHE'}{'Useflags'}{'getUsedescs'}{$k1}{'use.local.desc'}=undef;
	}

	# - Useflags - getUsemasksFromProfile >
	$self->{'CACHE'}{'Useflags'}{'getUsemasksFromProfile'}{'useflags'}=undef;

	return 1;
}

# Description:
# Search packages by maintainer. Returns an array of packages.
# @packages=$pxs->searchPackageByMaintainer($searchString,[$repo]);
# Example:
# @packages=$pxs->searchPackageByMaintainer('ian@gentoo.org');
# @packages=$pxs->searchPackageByMaintainer('ian@gentoo.org','/usr/local/portage/');
sub searchPackageByMaintainer {
	my $self		= shift;
	my $searchString	= shift;
	my $repo		= shift;
	my $dhc;
	my $dhp;
	my $tc;
	my $tp;
	my @matches		= ();
	my @fields		= ();

	#if (!$mode) { $mode='like'; }
	$repo=$self->portdir if (!$repo);
	if (!-d $repo) { return (); }

	# - read categories >
	foreach my $pkg ($self->searchPackage('','like',$repo)) {
		my $metaxml = path($repo)->child($pkg, 'metadata.xml');
		if (-e $metaxml ) {
			my $buffer= $metaxml->slurp();
			if ($buffer =~ m/<email>$searchString(.*)?<\/email>/i) {
				push(@matches,$pkg);
			}
			elsif ($buffer =~ m/<name>$searchString(.*)?<\/name>/i) {
				push(@matches,$pkg);
			}
		}
	}

	return (sort @matches);
}

# Description:
# Search packages by herd. Returns an array of packages.
# @packages=$pxs->searchPackageByHerd($searchString,[$repo]);
# Example:
# @packages=$pxs->searchPackageByHerd('perl');
# @packages=$pxs->searchPackageByHerd('perl','/usr/local/portage/');
sub searchPackageByHerd {
	my $self		= shift;
	my $searchString	= shift;
	my $repo		= shift;
	my $dhc;
	my $dhp;
	my $tc;
	my $tp;
	my @matches		= ();
	my @fields		= ();

	#if (!$mode) { $mode='like'; }
	$repo=$self->portdir if (!$repo);
	if (!-d $repo) { return (); }

	# - read categories >
	foreach my $pkg ($self->searchPackage('','like',$repo)) {
		my $metaxml = path($repo)->child($pkg, 'metadata.xml');
		if (-e $metaxml ) {
			my $buffer= $metaxml->slurp();
			if ($buffer =~ m/<herd>$searchString(.*)?<\/herd>/i) {
				push(@matches,$metaxml->parent);
			}
		}
	}

	return (sort @matches);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::Core - Core behaviour role for C<PortageXS>

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::Core",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
