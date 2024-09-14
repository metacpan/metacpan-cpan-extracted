use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SignalWire::ML',
    VERSION_FROM      => 'lib/SignalWire/ML.pm', # finds $VERSION
    PREREQ_PM         => { 
        'YAML::PP' => "0.38.0",
        'JSON'     => 0,
        'Test::More' => 0, # Add this line for the test dependency
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Brian West <brian@signalwire.com>') : ()),
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    test => { TESTS => 't/*.t' }, # Add this line to include all test files
);
