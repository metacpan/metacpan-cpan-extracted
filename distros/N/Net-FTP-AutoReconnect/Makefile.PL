use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::FTP::AutoReconnect',
    'VERSION_FROM' => 'lib/Net/FTP/AutoReconnect.pm', # finds $VERSION
    'PREREQ_PM' => {
        Net::FTP 	=> 0,
      IO::Handle        => 0,
           Fcntl        => 0,
    },
);
