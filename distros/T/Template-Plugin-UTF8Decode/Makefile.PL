use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Template::Plugin::UTF8Decode',
    VERSION_FROM      => 'lib/Template/Plugin/UTF8Decode.pm', # finds $VERSION
    PREREQ_PM         => {
        'Template'       => 2.14,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/UTF8Decode.pm', # retrieve abstract from module
       AUTHOR         => 'Fabio Masini <fabio.masini@gmail.com>') : ()),
);
