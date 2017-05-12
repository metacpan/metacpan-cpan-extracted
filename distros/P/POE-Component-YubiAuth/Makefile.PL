use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::YubiAuth',
    AUTHOR              => q{Kirill Miazine <km@krot.org>},
    VERSION_FROM        => 'lib/POE/Component/YubiAuth.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/YubiAuth.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'feature' => 0,
        'Test::More' => 0,
        'POE::Session' => 0,
        'POE::Component::Client::HTTP' => 0,
        'HTTP::Request' => 0,
        'Digest::HMAC_SHA1' => 0,
        'String::Random' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-YubiAuth-*' },
);
