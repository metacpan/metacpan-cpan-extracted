use ExtUtils::MakeMaker;

WriteMakefile(NAME          => 'SOAP::UMRA',
              VERSION_FROM  => 'lib/SOAP/UMRA.pm',
              ABSTRACT_FROM => 'lib/SOAP/UMRA.pm',
              AUTHOR        => 'Dennis Kaarsemaker <dennis@kaarsemaker.net>',
              PREREQ_PM     => {'HTTP::Cookies' => '0',
                                'SOAP::Lite'    => '0'});
