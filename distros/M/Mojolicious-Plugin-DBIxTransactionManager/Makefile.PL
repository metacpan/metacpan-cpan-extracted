use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::DBIxTransactionManager',
    AUTHOR              => q{Tatsuya FUKATA <tatsuya.fukata@gmail.com >},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/DBIxTransactionManager.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/DBIxTransactionManager.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBIx::TransactionManager' => 1.11,
        'Mojolicious' => 3.63, 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-DBIxTransactionManager-*' },
);
