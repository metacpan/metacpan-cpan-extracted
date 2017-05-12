use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::ShowDiff',
    'VERSION_FROM'	=> 'ShowDiff.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Algorithm::Diff' => 1.15,
		'Term::ANSIColor' => 1.04,
		'Test::More'      => 0,
	}, # e.g., Module::Name => 1.1
	
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>',
       ABSTRACT   => 'Perl extension to help visualize differences between strings'
      )
      : ()
     )
);
