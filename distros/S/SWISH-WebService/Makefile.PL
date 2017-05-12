use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SWISH::WebService',
    VERSION_FROM      => 'lib/SWISH/WebService.pm', # finds $VERSION
    PREREQ_PM         => { 
'SWISH::API::Remote'  => '0.10',
'SWISH::API'        	=> '0.04',
'Carp' => 0.01,
'Data::Dumper' => 0.01,
'URI::Escape'  => 0.01,
'Data::Pageset'  => 0.02,
'Template'     => 2.00,
'Search::Tools' => 0.01,
'Time::HiRes'   => 1, 
'Class::Accessor::Fast' => 0.22


}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISH/WebService.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <karpet@peknet.com>') : ()),
);
