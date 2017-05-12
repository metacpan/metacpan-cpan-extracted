use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MySQL::QueryMulti',
    AUTHOR        => q{John Gravatt <gravattj@cpan.org>},
    VERSION_FROM  => 'lib/MySQL/QueryMulti.pm',
    ABSTRACT_FROM => 'lib/MySQL/QueryMulti.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'SQL::Statement'   => 1.33,
        'DBI'              => 1.6,
        'DBD::mysql'       => 4.019,
        'Moose'            => 2.0403,
        'Text::ASCIITable' => 0.18,
        'Term::ReadLine'   => 1.07,
        'Time::HiRes'      => 0,
        'namespace::autoclean' => 0.13,
        
        # I had some older versions of these modules laying around and 
        # SQL::Statement 1.401 was failing some tests because of it.  
        # Therefore, I am requiring more recent versions that resolve the 
        # issues.  This should be communicated to the maintainer of 
        # SQL::Statement.
        'Math::Complex'    => 1.56, 
        'Math::BigInt'     => 1.994,

    },
    EXE_FILES => [ "bin/mysqlqm" ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'MySQL-QueryMulti-*' },
);
