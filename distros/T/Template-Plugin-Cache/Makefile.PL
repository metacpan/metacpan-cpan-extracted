use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::Cache',
    'VERSION_FROM'	=> 'Cache.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Template' => 2.07, 'Cache::Cache' => 1.02 },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
