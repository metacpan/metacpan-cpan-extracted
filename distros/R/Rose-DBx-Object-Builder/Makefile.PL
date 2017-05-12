use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::Object::Builder',
    AUTHOR              => 'Xufeng (Danny) Liang <danny.glue@gmail.com>',
    VERSION_FROM        => 'lib/Rose/DBx/Object/Builder.pm',
    ABSTRACT_FROM       => 'lib/Rose/DBx/Object/Builder.pm',
    ($^O =~ /darwin/i ?
       (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
    PREREQ_PM => {
        'Test::More' => 0,
        'Lingua::EN::Inflect' => 0,
        'Regexp::Common' => 0,
        'DBI' => 0,
    	'Rose::Object' => 0,
        'Exporter' => '5.57'
    },    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-Object-Builder-*' },
);