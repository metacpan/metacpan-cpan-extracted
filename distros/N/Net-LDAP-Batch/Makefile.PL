use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::LDAP::Batch',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/Net/LDAP/Batch.pm',
    ABSTRACT_FROM       => 'lib/Net/LDAP/Batch.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Accessor::Fast' => 0,
        'Scalar::Util' => 0,
        'Data::Dump' => 0,
        'Net::LDAP'  => 0,
        'Net::LDAP::Server::Test' => 0.04,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-LDAP-Batch-*' },
);
