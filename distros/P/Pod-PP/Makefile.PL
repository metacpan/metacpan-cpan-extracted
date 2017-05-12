#
# $Id: Makefile.PL,v 0.1 2001/04/25 10:41:48 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Makefile.PL,v $
# Revision 0.1  2001/04/25 10:41:48  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use ExtUtils::MakeMaker;
eval q(use Carp::Datum::MakeMaker;);

my %PL_FILES = map
	{ ($a = $_) =~ s/\.PL// ? ($_,$a) : () }
	glob('scripts/*.PL');

WriteMakefile(
    'NAME'	=> 'Pod::PP',
    'VERSION_FROM' => 'PP.pm', # finds $VERSION
	'PL_FILES'	=> \%PL_FILES,
	'EXE_FILES'	=> [ values %PL_FILES ],
	'PREREQ_PM' => {
		'Carp::Datum'	=> '0.100',
		'Log::Agent'	=> '0.207',
		'Pod::Parser'	=> '1.13',
		'Getargs::Long'	=> '0.103',
		'Clone'			=> '0.09',
	},
    'LIBS'	=> [''],		# e.g., '-lm' 
    'DEFINE'	=> '',		# e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',			# e.g., '-I/usr/include/other' 
);

