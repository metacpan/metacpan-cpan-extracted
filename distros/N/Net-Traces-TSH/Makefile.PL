use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME          => 'Net::Traces::TSH',
	      VERSION_FROM  => 'TSH.pm',
	      PREREQ_PM     => { Carp => 0},
	      ABSTRACT_FROM => 'TSH.pm',
	      AUTHOR        => 'Kostas Pentikousis <kostas@cpan.org>',
	     );
