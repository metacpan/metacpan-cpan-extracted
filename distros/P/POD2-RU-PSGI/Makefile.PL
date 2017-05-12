use strict;
use warnings;
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => 'https://github.com/vti/psgi-specs-ru.git',
        },
    }
};

WriteMakefile(
    NAME   => 'POD2::RU::PSGI',
    AUTHOR => 'Илья Чесноков, Денис Федосеев, Олег Алистратов, Александр Воронов, Вячеслав Тихановский',
    VERSION_FROM => 'lib/POD2/RU/PSGI.pm',
    ABSTRACT     => 'Документация PSGI по-русски',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {},
    clean     => {FILES => 'POD2-RU-PSGI-*'},
);
