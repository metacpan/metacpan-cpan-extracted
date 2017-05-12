use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::HTMLx::Form::Field::Boolean',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/Rose/HTMLx/Form/Field/Boolean.pm',
    ABSTRACT_FROM       => 'lib/Rose/HTMLx/Form/Field/Boolean.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    #    'Rose::HTML::Objects' => 0,
        'Rose::HTML::Form::Field::RadioButton' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-HTMLx-Form-Field-Boolean-*' },
);
