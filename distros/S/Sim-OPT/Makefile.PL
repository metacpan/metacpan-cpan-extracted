#use 5.014001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sim::OPT',
    VERSION_FROM      => 'lib/Sim/OPT.pm', # finds $VERSION
    PREREQ_PM         => {
			'Data::Dumper' => '0',		
			'Data::Dump' => '0',
			'Math::Round'	=> '0',
			'Math::Trig'  => '0',
			'List::Util' => '0',
			'List::AllUtils' => '0',
			'List::MoreUtils' => '0',
			'List::Compare'  => '0',
			'Moose'  => '0',
			#'Statistics::Basic'  => '0',
			'IO::Tee'  => '0',
			'Set::Intersection'  => '0',
			'Storable'  => '0',
			'File::Copy' => '0',
			'warnings::unused' => '0',
			'Vector::Object3D::Polygon' => '0',
			'Math::Polygon::Tree' => '0',
			'Devel::REPL' => '0',
			'Regexp::Common' => '0',
			#'Parallel::ForkManager' => '0',
			'MCE::Loop' => '0',
			'Scalar::Util' => '0',
			}, # e.g., Module::Name => 1.1
    ($] >= 5.014 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Sim::OPT is a optimization and parametric exploration program that can mix sequential and parallel block search methods.', # retrieve abstract from module
       AUTHOR         => 'Gian Luca Brunetti <gianluca.brunetti@polimi.it>') : ()),
);

