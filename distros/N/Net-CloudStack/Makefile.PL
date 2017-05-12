use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::CloudStack',
    AUTHOR              => q{Shugo Numano <numano@cc.rim.or.jp>},
    VERSION_FROM        => 'lib/Net/CloudStack.pm',
    ABSTRACT_FROM       => 'lib/Net/CloudStack.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
	'Mouse'          => 0,
	'Mouse::Util::TypeConstraints' => 0,
	'Digest::SHA'    => 0,
	'MIME::Base64'   => 0,
	'HTTP::Response' => 0,
	'LWP::UserAgent' => 0,
	'Encode'         => 0,
	'XML::Twig'      => 0,
	'URI::Encode'    => 0,
	'JSON'           => 0,
	'Carp'           => 0,
	'XML::Simple'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-CloudStack-*' },
);
