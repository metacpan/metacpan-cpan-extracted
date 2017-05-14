
use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> q[Perl6::Currying],
		VERSION => q[0.05],
		PREREQ_PM => { 'Filter::Simple' => 0.78 }

	     );
