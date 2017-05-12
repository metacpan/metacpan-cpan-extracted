eval {
    require DBI;
    require DBI::DBD;
    require DBD::SQLite;
    die "Too old" unless DBD::SQLite::VERSION >= 0.31;
};

use ExtUtils::MakeMaker;
use Config;
use strict;

WriteMakefile(
    NAME          => 'SQLite::DB',
    ($[ >= 5.005) ?
    (AUTHOR   => 'Vitor Serra Mori (vvvv767@hotmail.com)',
     ABSTRACT => 'Object Oriented Wrapper to SQLite databases') : (),
     VERSION_FROM => "lib/SQLite/DB.pm",
     PREREQ_PM    => { 'DBD::SQLite' => 0.31 },
);
