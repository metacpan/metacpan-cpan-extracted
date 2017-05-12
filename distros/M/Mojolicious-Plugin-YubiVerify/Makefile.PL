use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::YubiVerify',
    AUTHOR              => q{Kirill Miazine <km@krot.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/YubiVerify.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/YubiVerify.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojolicious::Plugin' => 0,
        'Mojo::UserAgent' => 0,
        'URI::Escape' => 0,
        'MIME::Base64' => 0,
        'Digest::HMAC_SHA1' => 0,
        'String::Random' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-YubiVerify-*' },
);
