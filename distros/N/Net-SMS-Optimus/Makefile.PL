use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMS::Optimus',
    AUTHOR              => 'Ruben Fonseca <root@cpan.org>',
    VERSION_FROM        => 'lib/Net/SMS/Optimus.pm',
    ABSTRACT_FROM       => 'lib/Net/SMS/Optimus.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 2.033,
        'HTTP::Cookies'  => 1.39,
        'HTML::Form'     => 1.054,
        'Crypt::SSLeay'  => 0.53,
    },
    EXE_FILES => [ 'lib/sms_optimus' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMS-Optimus-*' },
);
