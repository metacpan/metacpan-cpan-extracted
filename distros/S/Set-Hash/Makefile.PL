use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'     => 'Set::Hash',
    'VERSION_FROM'   => 'Set/Hash.pm', # finds $VERSION
    'PREREQ_PM'      => {'Want' => '0.05','Set::Array' => '0.10'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Set/Hash.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel J. Berger <djberg96 at yahoo dot com>') : ()),
);
