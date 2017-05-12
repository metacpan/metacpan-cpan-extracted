package Module::Mapper;

use Getopt::Long qw(:config no_ignore_case permute);
use File::Spec::Functions qw(splitpath catpath);
use File::Path;
use File::Find;
use Pod::Usage;

use base ('Exporter');

@EXPORT = ('find_sources');
$VERSION = '1.01';

use strict;
use warnings;

sub find_sources {
	my %options = @_;

	my $all = $options{All};
	my $path = $options{Output};
	my $verbose = $options{Verbose};
	my @modules = $options{Modules} ? @{$options{Modules}} : ();
	my @localdirs = $options{Libs} ? @{$options{Libs}} : ();
	my @exes = $options{Scripts} ? @{$options{Scripts}} : ();
	my $useINC = $options{UseINC};
	my $usepod = $options{IncludePOD};
	my $projdir = $options{Project} || '.';

	$@ = "-verbose must be a coderef\n",
	return undef
		if $verbose && (ref $verbose ne 'CODE');
#
#	normalize and test for the directories
#
	foreach (@localdirs) {
		s![/\\]$!!;
		$@ = "Cannot find directory $_, exitting.\n",
		return undef
			unless -d;
	}

	$@ = "Nothing to do, exitting (perhaps you forgot -exes or -modules ?).",
	return undef
		if $useINC && (! scalar @localdirs) && (! scalar @modules) && (! scalar @exes);

	my $havepath = defined $path;
	my @files = ();
	my %exes = ();
	my %modules = ();
	if ((! scalar @modules) && (! scalar @exes)) {
#
#	project mode
#
		$projdir=~s!/$!!;
		$@ = "No local project directories",
		return undef
			unless -d "$projdir/bin" || -d "$projdir/lib";
		$verbose->("Project mode: Scanning $projdir/bin and $projdir/lib...\n") if $verbose;
		if (opendir(INDIR, "$projdir/bin")) {
			while (my $file = readdir(INDIR)) {
				$exes{"$projdir/bin/$file"} = $havepath ? "$path/bin/$file" : 1
					unless -d "$projdir/bin/$file";
			}
			closedir INDIR;
		}
	
		_collectFiles("$projdir/lib", $usepod, \%modules, "$path/blib", '');
		
		if ($verbose) {		
			if ($havepath) {
				$verbose->("$_ maps to $exes{$_}\n")
					foreach (sort keys %exes);
			}
			else {
				$verbose->("Found $_\n")
					foreach (sort keys %exes);
			}
		}
#
#	trim any empty namespaces
#
		foreach (sort keys %modules) {
			delete $modules{$_},
			next 
				unless ($#{$modules{$_}} > -1);
			$verbose->(defined $modules{$_}[0] ?
				($havepath ?
					"$_ found in $modules{$_}[0] maps to $modules{$_}[1]\n" :
					"$_ found in $modules{$_}[0]\n") :
				($havepath ?
					"$_ found in $modules{$_}[2] maps to $modules{$_}[3]\n" :
					"$_ found in $modules{$_}[2]\n"))
					if $verbose;
		}

		$modules{$_} = [ $_, $exes{$_} ]
			foreach (keys %exes);

		return \%modules;
	}
#
#	process exes first
#
	foreach (@exes) {
		$verbose->("$_ not found\n") unless -e || (! $verbose);

		$@ = "$_ not a file\n",
		return undef
			if -d;
		my ($volume, $subdir, $file) = splitpath( $_ );
		$exes{$_} = $havepath ? "$path/bin/$file" : 1;
	}
#
#	now modules
#
	foreach my $module (@modules) {
		my $srcfile = "$module.pm";
		my $podfile = "$module.pod";
		my $root = $module;
		$srcfile=~s!\:\:!/!g;
		$podfile=~s!\:\:!/!g;
		$root=~s!\:\:!/!g;
		my $outroot = $havepath ? "$path/$root" : undef;
		my $hasdir;
	
		foreach (@localdirs) {
			$verbose->("Scanning $_ for $module...\n") if $verbose;
			$modules{$module} = [ "$_/$srcfile", ($havepath ? "$path/blib/$srcfile" : 1) ]
				if -e "$_/$srcfile";
	
			$modules{$module} ||= [ undef, undef ],
			push @{$modules{$module}}, "$_/$podfile", ($havepath ? "$path/blib/$podfile" : 1)
				if $usepod && (-e "$_/$podfile");
#
#	might be namespace parent 
#
			$modules{$module} ||= []
				if (-d "$_/$root");

			$outroot = "$path/blib/$root",
			$root = "$_/$root",
			last
				if exists $modules{$module};
		}
		if ($useINC && (! exists $modules{$module})) {
			foreach (@INC) {
				$verbose->("Scanning $_ for $module...\n") if $verbose;
				$modules{$module} = [ "$_/$srcfile", ($havepath ? "$path/lib/$srcfile" : 1) ]
					if -e "$_/$srcfile";
	
				$modules{$module} ||= [ undef, undef ],
				push @{$modules{$module}}, "$_/$podfile", ($havepath ? "$path/lib/$podfile" : 1)
					if $usepod && (-e "$_/$podfile");
#
#	might be namespace parent 
#
				$modules{$module} ||= []
					if (-d "$_/$root");
				$outroot = ($havepath ? "$path/lib/$root" : undef),
				$root = "$_/$root",
				last
					if exists $modules{$module} || (-d "$_/$root");
			}
		}
		unless ($all && exists $modules{$module}) {
			$verbose->("$module not found\n") if $verbose;
			next;
		}

		next unless $all;
#
#	recurse into subdirs and collect all the package/pods
#
		$verbose->("$module found, scanning for children...\n") if $verbose;
		_collectFiles($root, $usepod, \%modules, $outroot, $module);
		if ($#{$modules{$module}} == -1) {
#
#	check if any children found
#
			my $childcnt = 0;
			$module .= '::';
			while (my ($m, $c) = each %modules) {
				$childcnt++, last
					if ($#$c > -1) &&
						(length($m) > 2 + length($module)) &&
						(substr($m, 0, length($module)) eq $module);
			}
			$verbose->("$module namespace is empty\n") unless $childcnt || (! $verbose);
		}
	}

	if ($verbose) {		
		if ($havepath) {
			$verbose->("$projdir/bin/$_ maps to $exes{$_}\n")
				foreach (sort keys %exes);
		}
		else {
			$verbose->("Found $_ in $projdir/bin\n")
				foreach (sort keys %exes);
		}
	}
	foreach (sort keys %modules) {
#
#	trim any empty namespaces
#
		delete $modules{$_},
		next 
			unless ($#{$modules{$_}} > -1);

		$verbose->(defined $modules{$_}[0] ?
			($havepath ?
				"$_ found in $modules{$_}[0]\n\tmaps to $modules{$_}[1]\n" :
				"$_ found in $modules{$_}[0]\n") :
			($havepath ?
				"$_ found in $modules{$_}[2]\n\tmaps to $modules{$_}[3]\n" :
				"$_ found in $modules{$_}[2]\n"))
				if $verbose;
	}

	$modules{$_} = [ $_, $exes{$_} ]
		foreach (keys %exes);

	return \%modules;
}

sub _collectFiles {
	my ($dir, $usepod, $modules, $outpath, $pkgroot) = @_;
	my @children = ();
	opendir(INDIR, $dir) or return $modules;
	while (my $child = readdir(INDIR)) {
		push (@children, $child)
			if (substr($child, 0, 1) ne '.') && -d "$dir/$child";

		next
			if -d "$dir/$child";

		if ((substr($child, -3) eq '.pm') || (substr($child, -4) eq '.pod')) {
			$child=~s/\.(pm|pod)$//;
			my $module = $pkgroot ? "$pkgroot\::$child" : $child;
			$modules->{$module} ||= [];
			if ($1 eq 'pm') {
				$modules->{$module}[0] = "$dir/$child.pm";
				$modules->{$module}[1] = $outpath ? "$outpath/$child.pm" : 1;
			}
			else {
				$modules->{$module}[2] = "$dir/$child.pod";
				$modules->{$module}[3] = $outpath ? "$outpath/$child.pod" : 1;
			}
		}
	}
	closedir INDIR;
	_collectFiles("$dir/$_", $usepod, $modules, ($outpath ? "$outpath/$_" : undef), 
		($pkgroot ? "$pkgroot\::$_" : $_) )
		foreach (@children);
	return $modules;
}

1;