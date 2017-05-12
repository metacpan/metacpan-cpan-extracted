use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Date::Time',
    'VERSION_FROM' => 'Time.pm', # finds $VERSION
    DISTNAME => 'OO-DateTime',
    'dist' => {
        COMPRESS => 'gzip -9', 
	SUFFIX => '.gz', 
	DIST_DEFAULT => 'all tardist', 
	DISTNAME => 'OO-DateTime' 
    }
);
