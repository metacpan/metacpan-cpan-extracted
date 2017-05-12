use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SOAP::Transport::HTTP::Nginx',
    AUTHOR              => 'Alexander Soudakov <cygakoB@gmail.com>',
    VERSION_FROM        => 'lib/SOAP/Transport/HTTP/Nginx.pm',
    ABSTRACT_FROM       => 'lib/SOAP/Transport/HTTP/Nginx.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'XMLRPC::Transport::HTTP'	=> 0,
		'SOAP::Transport::HTTP'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SOAP-Transport-HTTP-Nginx-*' },
);
