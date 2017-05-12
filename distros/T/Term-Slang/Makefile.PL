# $Id: Makefile.PL,v 1.2 1999/12/22 23:55:34 daniel Exp $

require 5.004_04;
use ExtUtils::MakeMaker;
use Config qw(%Config);

sub MY::libscan {
	my ($self,$path) = @_;

	return '' if($path =~ m:/(RCS|CVS|SCCS)/: ||
		$path =~ m:[~%]$: ||
		$path =~ m:\.(orig|rej)$:
	);

	return $path;
}

print "Checking for 'slang.h'\n";
my $include = '';
my @inc = split /\s+/,join(' ',$Config{'usrinc'},$Config{'incpth'},$Config{'locincpth'});
foreach my $path (@inc) {
	if (-f "$path/slang.h") {
		print "Checking in $path/...\n";
		$include .= "-I$path ";
        	last;
	} elsif (-f "$path/slang/slang.h") {
		print "Checking in $path/slang/...\n";
		$include .= "-I$path/slang ";
		last;
	}
}

die "I can't find 'slang.h' - Exiting!\n" if $include =~ /^\s*$/;

WriteMakefile(
	'NAME'		=> 'Term::Slang',
	'VERSION_FROM'	=> 'Slang.pm',
	'LIBS'		=> ['-lslang'],
	'DEFINE'	=> '',
	'INC'		=> $include,
	'PMLIBDIRS'	=> [ 'Slang' ],
	'dist'		=> {	COMPRESS => 'gzip -9f',
				SUFFIX   => 'gz',
				DIST_DEFAULT => 'tardist',
	},
);
