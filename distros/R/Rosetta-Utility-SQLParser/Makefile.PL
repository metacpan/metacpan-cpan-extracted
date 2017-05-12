#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Rosetta::Utility::SQLParser',
    'VERSION_FROM' => 'lib/Rosetta/Utility/SQLParser.pm', # finds $VERSION
    'PREREQ_PM' => {
        'version' => 0,
        'only' => 0,
        'Test::More' => 0, # but only for the test suite
        'Locale::KeyedText' => '1.6.0',
        'Rosetta::Model' => '0.71.0',
    },
);

1;
