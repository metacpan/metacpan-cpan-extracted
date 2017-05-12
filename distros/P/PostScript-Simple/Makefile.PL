use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PostScript::Simple',
    'VERSION_FROM'	=> 'lib/PostScript/Simple.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::More' => 0.18, ### Requires Test::More by tests.(Test::Simple and Test::Utils is not used.)
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/PostScript/Simple.pm', # retrieve abstract from module
       AUTHOR     => 'Matthew Newton <mcnewton@cpan.org>') : ()),
);
