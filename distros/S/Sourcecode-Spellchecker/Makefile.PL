use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sourcecode::Spellchecker',
    VERSION_FROM      => 'lib/Sourcecode/Spellchecker.pm', # finds $VERSION
    PREREQ_PM         => { 'Test::More' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sourcecode/Spellchecker.pm', # retrieve abstract from module
       AUTHOR         => 'Zachary Blair <zblair@cpan.org>') : ()),
);
