use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::SCP',
    'VERSION_FROM' => 'SCP.pm', # finds $VERSION
    'PREREQ_PM' => {
                     'Net::SSH'           => 0,
                     'String::ShellQuote' => 0,
                     'IO::Handle'         => 0
                   },
);
