#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Number::DataRate',
    VERSION_FROM => 'lib/Number/DataRate.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::More'              => '0',
        'Class::Accessor::Faster' => '0',
        'Regexp::Common'          => '0',
    },
);
