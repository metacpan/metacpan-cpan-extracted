use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Radius::Client',
    'VERSION_FROM'	=> 'Client.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Net::Radius::Dictionary' => 1.55,
        'Net::Radius::Packet'     => 1.55,
	'IO::Socket::INET'        => 1.27,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ('ABSTRACT_FROM' => 'Client.pm', # retrieve abstract from module
       'AUTHOR'        => 'Ilya Etingof <ilya@glas.net>') : ()),
);
