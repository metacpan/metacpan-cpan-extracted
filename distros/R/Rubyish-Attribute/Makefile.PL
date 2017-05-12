# use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Rubyish::Attribute',
    VERSION_FROM      => 'lib/Rubyish/Attribute.pm',
    ABSTRACT_FROM     => 'lib/Rubyish/Attribute.pm',
    AUTHOR            => 'shelling, <navyblueshellingford@gmail.com>',
    MIN_PERL_VERSION  => '5.010',
    PREREQ_PM         => {
            PadWalker       =>        0,
            Want            =>        0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rubyish-Attribute-* MANIFEST.bak MANIFEST' },
);
