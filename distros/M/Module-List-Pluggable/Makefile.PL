use 5.8.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Module::List::Pluggable',
    VERSION_FROM      => 'lib/Module/List/Pluggable.pm', # finds $VERSION
    PREREQ_PM         => {
                          Class::Base  => 0.03,
                          Module::List => 0.001,
                          Test::More   => 0.64,
                          Exporter     => 0,
                          Data::Dumper => 0,
                          Carp         => 0,
                          lib          => 0,
                          FindBin      => 0,
                          File::Find   => 0,
                         },
   ($] >= 5.005 ? ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/Module/List/Pluggable.pm', # retrieve abstract from module
     AUTHOR         => 'Joseph Brenner <doom@kzsu.stanford.edu>') : ()),
);
