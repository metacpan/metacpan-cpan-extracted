use 5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SVG::Shapefile',
    VERSION_FROM      => 'lib/SVG/Shapefile.pm', # finds $VERSION
    PREREQ_PM         => {
	"SQL::Statement" => 0.01,
	# because dbd::excel fails install aiwthout it :/	
	"DBD::Excel"  => 0.06,
	"SVG" => 0.1,
	"Geo::Shapelib" => 0.09,	
	"Compress::Zlib" => 0.1,
    }, # e.g., Module::Name => 1.1
);
