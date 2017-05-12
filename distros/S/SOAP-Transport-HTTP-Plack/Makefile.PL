use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SOAP::Transport::HTTP::Plack',
    AUTHOR              => q{Elena Bolshakova <e.a.bolshakova@yandex.ru>},
    VERSION_FROM        => 'lib/SOAP/Transport/HTTP/Plack.pm',
    ABSTRACT_FROM       => 'lib/SOAP/Transport/HTTP/Plack.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XMLRPC::Transport::HTTP'   => 0,
        'SOAP::Transport::HTTP'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SOAP-Transport-HTTP-Plack-*' },
);
