use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::SMS::O2',
    'VERSION_FROM'	=> 'O2.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Crypt::SSLeay   => 0,
        Net::SMS::Web   => 0,
        URI::Escape     => 0,
    }, # e.g., Module::Name => 1.1
);
