
use ExtUtils::MakeMaker;
WriteMakefile
(
	NAME			=> 'Quantum::Superpositions',
	VERSION_FROM	=> 'lib/Quantum/Superpositions.pm',
	ABSTRACT		=> 'Superpositional logic in a single universe',
	PREREQ_PM =>
	{
		Carp				=> 0,	# standard distribution
		strict				=> 0,	# ditto
		Class::Multimethods	=> 0,	# nonstandard, at best...
	},
);
