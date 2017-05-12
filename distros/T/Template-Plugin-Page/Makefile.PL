use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::Page',
    'VERSION_FROM'	=> 'Page.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Template' => 2.07, 'Data::Page' => 0.14 },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
