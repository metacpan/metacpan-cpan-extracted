use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR  => 'Philip Gwyn <gwyn -at- cpan.org>',
    NAME	=> 'POE::Component::IKC',
    VERSION_FROM => 'IKC.pm', # finds $VERSION
    DISTNAME => 'POE-Component-IKC',
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
    PREREQ_PM =>{
            POE          => 1.311,
            Scalar::Util => 1,
            Test::More   => 0.6,
            Data::Dump   => 1,
            Devel::Size  => 0.77
        },
    ABSTRACT => 'Inter-Kernel Communication for POE',
    LICENSE => 'perl'    
);
