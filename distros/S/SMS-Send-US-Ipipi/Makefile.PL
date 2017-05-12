use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME              => 'SMS::Send::US::Ipipi',
              VERSION_FROM      => 'lib/SMS/Send/US/Ipipi.pm', # finds $VERSION
              PREREQ_PM         => { 'Carp'            => 0,
                                     'SMS::Send'       => '0.02',
                                     'WWW::Mechanize'  => '1.06',
                                     'IO::Socket::SSL' => '0.97',
                                     'LWP'             => '5.69',
                                     'File::Spec'      => '0.80',
                                     'Test::More'      => '0.47',
                                }, # e.g., Module::Name => 1.1
              ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM  => 'lib/SMS/Send/US/Ipipi.pm', # retrieve abstract from module
                AUTHOR         => 'Andrew Moore <andrew.moore@liblime.com>') : ()),
);
