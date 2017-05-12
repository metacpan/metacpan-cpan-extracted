use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Symbol::Opaque',
    VERSION_FROM      => 'lib/Symbol/Opaque.pm',
    PREREQ_PM         => {
        Class::Multimethods::Pure => 0,
    },
    ABSTRACT_FROM  => 'lib/Symbol/Opaque.pm',
    AUTHOR         => 'Luke Palmer <lrpalmer@gmail.com>',
);
