use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'Net::OpenSSH::Compat',
               VERSION_FROM => 'lib/Net/OpenSSH/Compat.pm',
               PREREQ_PM    => { "Net::OpenSSH" => "0.53_03" },
               AUTHOR       => 'Salvador Fandino <sfandino@yahoo.com>'
             );
