use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::Icecast::Source',
    VERSION_FROM      => 'lib/Net/Icecast/Source.pm',
    PREREQ_PM         => {
		'IO::Socket::INET' => '',
		'IO::Handle' => '',
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Net/Icecast/Source.pm',
       AUTHOR         => 'Mischa Spiegelmock <revmischa@cpan.org>') : ()),
);
