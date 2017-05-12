use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::LDAP::Entry::ToText',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Net/LDAP/Entry/ToText.pm',
    ABSTRACT_FROM       => 'lib/Net/LDAP/Entry/ToText.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-LDAP-Entry-ToText-*' },
);
