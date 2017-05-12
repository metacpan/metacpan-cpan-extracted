#! /usr/bin/perl -w -I ..

use strict;
use Cwd;
use File::Find;
use PML;

my $MODULE = '';
my $VERSION = shift || PML->VERSION();

if (cwd =~ /tools$/)
{
	chdir '..';
}

cwd =~ /^.*\/(.*)$/;
$MODULE = $1;

# make docs
opendir DIR, 'doc/src';
my @docs = grep {(not /^\./ and not /^CVS$/) and -e "doc/src/$_/Makefile"} readdir DIR;
closedir DIR;
foreach (@docs) {
	print "cd doc/src/$_; make; make clean\n";
	my $cwd = cwd;
	chdir "doc/src/$_";
	system('make; make clean');
	chdir $cwd
}

# build the readme file
system("cp COPYRIGHT README; pod2text PML.pm >> README");
system("perl -w -i -n -e 'print if /^#/ .. /pml-custom-app/' README");

chdir '..';
system("cp -RP $MODULE $MODULE-$VERSION");
$MODULE = "$MODULE-$VERSION";

chdir $MODULE;
system ('make realclean') if -e 'Makefile';

my @files;
my $path;
my $cwd = cwd;

find(sub
{
	return if $_ eq 'MANIFEST';

	if ($_ eq 'CVS')
	{
		$File::Find::prune = 1;
		return;
	}

	unless (-d $_)
	{
		$path = $File::Find::name;
		$path =~ s/^$cwd\///;
		push(@files, $path);
	}
}, $cwd);

push(@files, 'MANIFEST');

open (M, '>MANIFEST') || die $!;
print M join("\n", @files), "\n";
close M;

chdir '..';

open T, ">tarlist_for_$MODULE" || die $!;
print T "$MODULE/", join("\n$MODULE/", @files), "\n";
close T;

system("tar -c -z -v -T tarlist_for_$MODULE -f $MODULE.tar.gz");
unlink "tarlist_for_$MODULE";
system("rm -rf $MODULE");
