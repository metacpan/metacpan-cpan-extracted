use 5.008;
use ExtUtils::MakeMaker;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'SVG::GD',
    VERSION_FROM      => 'lib/SVG/GD.pm', # finds $VERSION
    PREREQ_PM         => { 'SVG::Parser'=>0.9,
			   'Test::More' => 0,
			   'Test::Pod' => 0,
			   'Test::Pod::Coverage' => 0,
			   'GD'=>0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
	#ABSTRACT_FROM  => 'lib/SVG/GD.pm', # retrieve abstract from module
       LICENSE        => 'perl',
       AUTHOR         => 'Ronan Oger<ronan@cpan.org>') : ()),
);

