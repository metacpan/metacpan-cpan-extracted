use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMS::MyTMN',
    AUTHOR              => 'Miguel Santinho <msantinho@simplicidade.com>',
    VERSION_FROM        => 'lib/Net/SMS/MyTMN.pm',
    ABSTRACT_FROM       => 'lib/Net/SMS/MyTMN.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'WWW::Mechanize' => 1.22,
		'Crypt::SSLeay' => 0.53,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMS-MyTMN-*' },
);
