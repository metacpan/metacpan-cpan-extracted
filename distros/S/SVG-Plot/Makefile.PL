use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SVG::Plot',
    'VERSION_FROM'	=> 'Plot.pm', # finds $VERSION
    'PREREQ_PM'		=> { Class::MethodMaker => 0.1,
                             SVG => 0.1,
                             Algorithm::Points::MinimumDistance => 0,
                             XML::XPath => 0, # for testing
                             Test::XML => '0.04' # XPath tests
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       AUTHOR     => 'jo walsh <jo@internal.cyberhqz.com>') : ()),
);
