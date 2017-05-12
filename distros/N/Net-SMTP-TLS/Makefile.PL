use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMTP::TLS',
    AUTHOR              => 'Alexander Christian Westholm <awestholm@verizon.net>',
    VERSION_FROM        => 'lib/Net/SMTP/TLS.pm',
    ABSTRACT_FROM       => 'lib/Net/SMTP/TLS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Net::SSLeay'=> 0,
	'IO::Socket::INET'=>0,
	'IO::Socket::SSL'=>0,
	'MIME::Base64'=>0,
	'Digest::HMAC_MD5'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMTP-TLS-*' },
);
