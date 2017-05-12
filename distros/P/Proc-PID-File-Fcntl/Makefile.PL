use ExtUtils::MakeMaker;

# Oh, the excruciating world of hurt that is ExtUtils::MakeMaker!

WriteMakefile (
	       NAME		=> 'Proc::PID::File::Fcntl',
	       VERSION_FROM	=> 'Fcntl.pm.PL',
	       AUTHOR		=> 'John Gardiner Myers <jgmyers@p'.'roofpoint.com>',
	       ABSTRACT_FROM	=> 'Fcntl.pm.PL',
	       PREREQ_PM	=> {'ExtUtils::CBuilder' => 0.07}, # Because MakeMaker has no obvious way to compile lockdefs.c
	       C		=> [],  # Prevent MakeMaker from trying to build a Fcntl.xs
	       PM		=> { 'Fcntl.pm' => '$(INST_ARCHLIB)/Proc/PID/File/Fcntl.pm' }, # Because MakeMaker can't figure this out by itself
	       clean		=> {FILES => 'Fcntl.pm lockdefs'},
);
