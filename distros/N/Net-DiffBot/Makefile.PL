use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DiffBot',
    AUTHOR              => q{Bruno Martins <bscmartins@gmail.com>},
    VERSION_FROM        => 'lib/Net/DiffBot.pm',
    ABSTRACT_FROM       => 'lib/Net/DiffBot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
		'LWP::UserAgent' => 0,
		'JSON::XS'       => 0,
		'URI::Escape'    => 0,
		'HTTP::Request'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DiffBot-*' },
);
