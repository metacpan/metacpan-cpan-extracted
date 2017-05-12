use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Squid::Auth::Plugin::UserList',
    AUTHOR        => 'Luis Motta Campos <lmc@cpan.org>',
    VERSION_FROM  => 'lib/Net/Squid/Auth/Plugin/UserList.pm',
    ABSTRACT_FROM => 'lib/Net/Squid/Auth/Plugin/UserList.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Squid-Auth-Plugin-UserList-*' },
);
