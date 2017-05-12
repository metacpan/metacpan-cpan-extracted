use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SVG::Template::Graph',
    VERSION_FROM => 'lib/SVG/Template/Graph.pm',    # finds $VERSION
    PREREQ_PM    => {
        'SVG::Parser'       => 1,
        'SVG'               => 2.38,
        'Transform::Canvas' => 0.02,
        'POSIX' 		  => 0.01,
        'Data::Dumper'      => 2.00,
        'Carp'              => 0.01,
        'Config::General'  => 0,
    },                                              # e.g., Module::Name => 1.1
    (
        $] >= 5.007
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/SVG/Template/Graph.pm',    # retrieve abstract from module
            AUTHOR 	  => 'Ronan Oger <ronan@cpan.org>',
	    LICENSE       => 'perl',
          )
        : ()
    ),
);
