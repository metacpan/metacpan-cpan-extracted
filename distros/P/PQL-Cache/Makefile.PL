use ExtUtils::MakeMaker;

@extras = ();

push(
    @extras,
    LICENSE => 'perl_5',
) if ( $ExtUtils::MakeMaker::Version >= 6.31 );

WriteMakefile(
    NAME              => 'PQL::Cache',
    VERSION_FROM      => 'lib/PQL/Cache.pm', # finds $VERSION
    PREREQ_PM         => { 'Test::Exception'	=> '0'}, # or => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PQL/Cache.pm', # retrieve abstract from module
       AUTHOR         => 'Ralf Peine <ralf.peine@jupiter-programs.de>') : ()),
);
