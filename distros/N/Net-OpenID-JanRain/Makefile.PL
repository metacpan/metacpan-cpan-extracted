#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Net::OpenID::JanRain',
    VERSION_FROM            => 'lib/Net/OpenID/JanRain/Util.pm', # finds $VERSION
    AUTHOR                  => 'Dag Arneson <dag@janrain.com>',
    ABSTRACT                => 'OpenID Server and Consumer with JanRain API',
    PREREQ_PM               => {
        'Net::Yadis' => 0,
        'Digest::HMAC_SHA1'  => 0,
        'MIME::Base64'  => 0,
        'LWP::UserAgent'  => 0,
        'Crypt::DH'  => 0,
        'Math::BigInt'  => 0,
        'URI'  => 0,
        'CGI'  => 0,
    },
);
