use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SVG::Graph',
    'VERSION_FROM'	=> 'Graph.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                            SVG => 2.27,
                            Statistics::Descriptive => 2.6,
                            Tree::DAG_Node => 1.04,
                            Math::Spline => 0.00,
                            Math::Derivative => 0.00,

                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Graph.pm', # retrieve abstract from module
       AUTHOR     => 'Allen Day <allenday@ucla.edu>, Chris To <crsto@ucla.edu>') : ()),
);
