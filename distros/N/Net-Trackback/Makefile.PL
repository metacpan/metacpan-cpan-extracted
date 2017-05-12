use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Trackback',
    'VERSION_FROM'	=> 'lib/Net/Trackback.pm',
    'PREREQ_PM'		=> { LWP=>5.8, Class::ErrorHandler=>0.01 }
);
