use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PheMail::Server',
    'VERSION_FROM'	=> 'Server.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Net::Server::Fork' => 0,
	'Math::XOR' => 0,
	'Digest::MD5' => 0,
	'PheMail::General' => 0,
	'Unix::Syslog' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Server.pm', # retrieve abstract from module
       AUTHOR     => 'Jesper Noehr <jesper@neohr.org>') : ()),
);
