use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::Substrings',
    'VERSION_FROM'	=> 'Substrings.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        String::Random    => 0,   # only for the tests
        Test::Differences => 0,
        Test::Exception   => 0,
        Test::More        => 0,
        Test::ManyParams  => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
