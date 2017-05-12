use ExtUtils::MakeMaker;
WriteMakefile( 'NAME' => 'Net::OpenID::Consumer::Yadis',
               'VERSION_FROM' => 'lib/Net/OpenID/Consumer/Yadis.pm',
               'PREREQ_PM'		=> {
                   'Net::OpenID::Consumer' => 0.12,
                   'Net::Yadis::Discovery'  => 0.05,
               },
               ($] >= 5.005 ?
                (ABSTRACT_FROM => 'lib/Net/OpenID/Consumer/Yadis.pm',
                 AUTHOR     => 'OHTSUKA Ko-hei <nene@kokogiko.net>') : ()),
               );
