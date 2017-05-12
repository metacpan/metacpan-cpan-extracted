require 5.008001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME    => 'TAP::Filter',
    AUTHOR  => 'Andy Armstrong <andy.armstrong@messagesystems.com>',
    LICENSE => 'perl',
    VERSION_FROM  => 'lib/TAP/Filter.pm',
    ABSTRACT_FROM => 'lib/TAP/Filter.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Data::Dumper'            => 0,
        'Storable'                => 0,
        'Test::More'              => 0,
        'Test::Deep'              => 0,
        'File::Spec'              => 0,
        'List::Util'              => 0,
        'TAP::Harness'            => '3.12',
        'TAP::Parser'             => '3.12',
        'TAP::Parser::Aggregator' => '3.12',
        'TAP::Parser::Result'     => '3.12',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TAP-Filter-*' },
);
