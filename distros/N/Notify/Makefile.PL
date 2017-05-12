use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	'NAME'      => 'Notify',
	'VERSION'   => '0.0.1',
	'PREREQ_PM' => {
		'Mail::Box' => 1.3,
		'Mail::Sender' => 0.7.10,
		'Tie::Persistent' => 0.9,
	}, # Such as Module::Name => 1.0
	($] >= 5.005 ?
		('ABSTRACT' => 'Modules for managing remote user notifications',
		 'AUTHOR'   => 'Michael Gilfix <mgilfix@eecs.tufts.edu>') : ()),
);
