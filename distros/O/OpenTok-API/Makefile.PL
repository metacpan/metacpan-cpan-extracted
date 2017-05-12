use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OpenTok::API',
    AUTHOR              => q{Maxim Nikolenko <root@zbsd.ru>},
    VERSION_FROM        => 'lib/OpenTok/API.pm',
    ABSTRACT_FROM       => 'lib/OpenTok/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Time::HiRes' => 0,
	'MIME::Base64' => 0,
	'Digest::HMAC_SHA1' => 0,
	'LWP' => 0,
	'XML::XPath' => 0,
	'Exception::Class' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OpenTok-API-*' },
);
