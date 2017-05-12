use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Nmap::Scanner',
    'VERSION_FROM' => 'lib/Nmap/Scanner.pm', # finds $VERSION
    'PREREQ_PM' => {
        'IPC::Open3'         => 0,
        'XML::SAX'           => 0,
        'Class::Generate'    => 0,
        'File::Temp'         => 0,
        'LWP::UserAgent'     => 0
    }
);
