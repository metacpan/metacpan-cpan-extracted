use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'PerlActor',
    VERSION_FROM      => 'lib/PerlActor.pm', # finds $VERSION
    PREREQ_PM         => { 
    						Test::Unit => 0.24,
    						Benchmark  => 1.00,
    						File::Find => 1.00
    					 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PerlActor.pm', # retrieve abstract from module
       AUTHOR         => 'Tony Byrne <perl@byrnehq.com>') : ()),
);
