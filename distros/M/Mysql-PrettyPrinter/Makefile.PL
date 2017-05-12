use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mysql::PrettyPrinter',
    AUTHOR              => q{Nic Sandfield <niczero@cpan.org>},
    VERSION_FROM        => 'lib/Mysql/PrettyPrinter.pm',
    ABSTRACT_FROM       => 'lib/Mysql/PrettyPrinter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mysql-PrettyPrinter-*' },
);
