use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::SSLify::NonBlock',
    AUTHOR              => 'Markus Mueller <pRiVi@cpan.org>',
    VERSION_FROM        => 'lib/POE/Component/SSLify/NonBlock.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/SSLify/NonBlock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::SSLeay'   => '1.32',
        'POE::Component::SSLify' => '0.06'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-SSLify-NonBlock-*' },
);
