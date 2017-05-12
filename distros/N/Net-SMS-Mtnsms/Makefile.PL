use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::SMS::Mtnsms',
    'VERSION_FROM'	=> 'Mtnsms.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Net::SMS::Web   => 0,
    }, # e.g., Module::Name => 1.1
);
