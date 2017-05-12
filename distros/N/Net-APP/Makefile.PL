use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::APP',
    'VERSION_FROM' => 'APP.pm', # finds $VERSION
    'PREREQ_PM' => { 'Net::Cmd' => 0,
#                     'IO::Socket::SSL' => 0,
#                     'Text::CSV_XS' => 0,
                   },
    'dist' => {},
);
