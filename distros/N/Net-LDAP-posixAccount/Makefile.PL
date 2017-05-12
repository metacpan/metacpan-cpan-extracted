use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::LDAP::posixAccount',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Net/LDAP/posixAccount.pm',
    ABSTRACT_FROM       => 'lib/Net/LDAP/posixAccount.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Net::LDAP::Entry' => 0,
        'Sys::User::UIDhelper' => 0,
		'Sys::Group::GIDhelper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-LDAP-posixAccount-*' },
);
