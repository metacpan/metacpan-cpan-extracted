use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RPC::Lite',
    VERSION_FROM      => 'lib/RPC/Lite.pm', # finds $VERSION
    PREREQ_PM         => {
                           'threads' => 0,
                           'threads::shared' =>  0,
                           'IO::Socket' => 0,
                           'IO::Select' => 0,
                           'Data::Dumper' => 0,
                           'JSON' => '1.07',
                           'XML::Simple' => '2.14',
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RPC/Lite.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Burke <aburke@bitflood.org>') : ()),
);
