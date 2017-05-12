use strict;
use warnings;
use ExtUtils::MakeMaker;

my @scripts = grep {-f } glob("scripts/*.pl "); # Ripped from Text::PDF

WriteMakefile(
	      NAME                => 'POE::Component::Algorithm::Evolutionary',
	      AUTHOR              => 'JJ Merelo <jj@merelo.net>',
	      VERSION_FROM        => 'lib/POE/Component/Algorithm/Evolutionary.pm',
	      ABSTRACT_FROM       => 'lib/POE/Component/Algorithm/Evolutionary.pm',
	      EXE_FILES => \@scripts,  
	      PL_FILES            => {},
	      PREREQ_PM => {
			    'Test::More' => 0,
			    'version'    => 0,
			    'POE'        => 0,
			    'Test::Output' => 0,
			    'Algorithm::Evolutionary' => 0.64 # this version fixes the problem with Statistic::Basic
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'POE-Component-Algorithm-Evolutionary-*' },
	     );
