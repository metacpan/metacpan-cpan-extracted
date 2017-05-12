use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Swig',
    AUTHOR              => q{David Chester <dchester@shutterstock.com>},
    VERSION_FROM        => 'lib/Template/Swig.pm',
    ABSTRACT_FROM       => 'lib/Template/Swig.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Exception' => 0,
        'Test::More'      => 0,
        'File::Slurp'     => 0,
        'JSON::XS'        => 0,
        'Test::Exception' => 0,
        'JavaScript::V8'  => 0
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/dchester/perl-template-swig'
        }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Swig-*' },
);
