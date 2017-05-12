
use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> q[Perl6::Export],
		VERSION => q[0.07],
        AUTHOR     => 'Damian Conway',
		PREREQ_PM  => { Filter::Simple=>0 },

	     );
