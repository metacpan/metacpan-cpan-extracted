use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::FTP::RetrHandle',
    'VERSION_FROM' => 'lib/Net/FTP/RetrHandle.pm', # finds $VERSION
    'PREREQ_PM' => {
        Net::FTP 	=> 0,
      IO::Handle        => 0,
           Fcntl        => 0,
    },
);
