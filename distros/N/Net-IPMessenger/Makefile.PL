use strict;
use warnings;
use ExtUtils::MakeMaker;

require 5.008001;

WriteMakefile(
    NAME                => 'Net::IPMessenger',
    AUTHOR              => 'Masanori Hara <massa.hara at gmail.com>',
    VERSION_FROM        => 'lib/Net/IPMessenger.pm',
    ABSTRACT_FROM       => 'lib/Net/IPMessenger.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor::Fast' => 0,
        'Encode'                => 0,
        'Test::More'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-IPMessenger-*' },
);
