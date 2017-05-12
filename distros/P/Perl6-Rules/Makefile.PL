
use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> q[Perl6::Rules],
		VERSION => q[0.03],
        AUTHOR     => 'Damian Conway',
   		PREREQ_PM  => { Filter::Simple=>0.78, Attribute::Handlers=>0.78 },

	     );
