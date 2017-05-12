# $Id: Makefile.PL,v 1.1 1998/11/04 17:11:49 daniel Exp daniel $

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

print "Checking for 'newt.h'\n";
my $include = '';
my @inc = split /\s+/,join(' ',$Config{'usrinc'},$Config{'incpth'},$Config{'locincpth'});
foreach my $path (@inc) {
	print "Checking in $path/...\n";
	if (-f "$path/newt.h") {
		$include .= "-I$path ";
        	last;
	}
}

die "I can't find 'newt.h' - Exiting!\n" if $include =~ /^\s*$/;

WriteMakefile(
	'NAME'		=> 'Term::Newt',
	'VERSION_FROM'	=> 'Newt.pm',
	'LIBS'		=> ['-lnewt -lslang'],
	'DEFINE'	=> '',
	'INC'		=> $include,
	'dist'		=> {	COMPRESS => 'gzip -9f',
				SUFFIX   => 'gz',
				DIST_DEFAULT => 'tardist',
	},
);
