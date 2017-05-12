use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage;";

WriteMakefile(
    NAME              => 'POEx::URI',
    AUTHOR            => "Philip Gwyn",
    VERSION_FROM      => 'lib/POEx/URI.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => {
            URI     => 1,
        }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POEx/URI.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <gwyn -at- cpan.org>') : ()),
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
);
