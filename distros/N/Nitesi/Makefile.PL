use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nitesi',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Nitesi.pm',
    ABSTRACT_FROM       => 'lib/Nitesi.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	    'ACL::Lite'  => 0.0003,
        'Crypt::Password' => 0.23,
        'Data::SimplePassword' => 0,
	'Moo' => 0.091004,
        'MooX::Types::MooseLike' => 0.16,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Nitesi-*' },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/Nitesi',
            bugtracker => 'https://github.com/interchange/Nitesi/issues',
        },
    },
);
