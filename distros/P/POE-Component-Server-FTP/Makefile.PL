use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::Server::FTP',
    'VERSION_FROM'	=> 'FTP.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			   Filesys::Virtual => 0.06,
			   IO::Scalar => undef,
			   IO::Socket::INET => undef,
			   Socket => undef,
               POE => undef,
	},
);
