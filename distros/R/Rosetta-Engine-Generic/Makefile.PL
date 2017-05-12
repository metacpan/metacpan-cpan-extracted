#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

warn <<__endquote;
------------------------------------------------------------
This distribution requires a live database to be tested against.  To gain the
best understanding of whether Rosetta::Engine::Generic will work with your
preferred database engine and/or working environment, you should edit this
distribution's test configuration file "t_setup.pl" prior to running 'make test'
and/or 'perl Makefile.PL'.  The setup details that you input should match a
visible database engine that you have full privileges on, including the ability
to create schema objects, and select or modify data.  If you do not edit
"t_setup.pl", such as when you are a fully-automatic CPAN tester, then the test
suite will use the newest SQLite v3 database engine by default, and the executed
tests will only be as thorough as the SQLite v3 feature set supports.
------------------------------------------------------------
__endquote

WriteMakefile(
    'NAME' => 'Rosetta::Engine::Generic',
    'VERSION_FROM' => 'lib/Rosetta/Engine/Generic.pm', # finds $VERSION
    'PREREQ_PM' => {
        'version' => 0,
        'only' => 0,
        'List::Util' => 0,
        'Test::More' => 0, # but only for the test suite
        'Rosetta' => '0.71.0',
        'Rosetta::Validator' => '0.71.0', # but only for the test suite
        'Rosetta::Utility::SQLBuilder' => '0.22.0',
        'Rosetta::Utility::SQLParser' => '0.3.0',
        'DBI' => '1.48',
        'DBD::SQLite' => '1.09', # default database engine used by the test suite
    },
);

1;
