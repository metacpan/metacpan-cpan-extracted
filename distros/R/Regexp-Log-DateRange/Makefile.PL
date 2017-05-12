use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Regexp::Log::DateRange',
    'VERSION_FROM' => 'DateRange.pm', 
    'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },

    'DISTNAME' => 'Regexp-Log-DateRange',
    'ABSTRACT' => 'Regexp for filtering log data on date range',
    'AUTHOR'   => 'Dmitry Karasik <dmitry@karasik.eu.org>',
);
