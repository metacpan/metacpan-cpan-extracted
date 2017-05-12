use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::Object::Renderer',
    AUTHOR              => 'Xufeng (Danny) Liang <danny.glue@gmail.com>',
	VERSION_FROM        => 'lib/Rose/DBx/Object/Renderer.pm',
    ($^O =~ /darwin/i ?
       (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
    PREREQ_PM => {
        'Test::More' => 0,
        'Lingua::EN::Inflect' => 0,
        'DateTime' => 0,
        'Rose::DB::Object::Loader' => 0,
    	'Rose::DB::Object::Helpers' => 0,
        'CGI' => 0,
        'CGI::FormBuilder' => '3.05',
        'Template' => 0,
        'Clone' => 0,
        'File::Path' => 0,
        'File::Copy' => 0,
        'File::Copy::Recursive' => 0,
        'File::Spec' => 0,
        'Digest::MD5' => 0,
        'Scalar::Util' => 0,
        'Exporter' => '5.57'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-Object-Renderer-*' },
);
