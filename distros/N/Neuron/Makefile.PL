
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME =>		'Neuron',
	VERSION_FROM	=> 'Neuron.pm',
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	);
