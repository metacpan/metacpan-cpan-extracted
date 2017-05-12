# $RCSfile: Makefile.PL,v $
# $Author: swaj $
# $Revision: 1.4 $

require 5.008;
use ExtUtils::MakeMaker;


WriteMakefile(

	      NAME              => 'Sdict',
	      VERSION_FROM      => 'lib/Sdict.pm',

	      EXE_FILES => [ "bin/sdict.plx",
			     "bin/dctinfo.plx",
			     "bin/sdict-tools.plx",
			   ],

	      PREREQ_PM         => { Compress::Zlib => 0.0 },

	      ( $] >= 5.005 ? ( ABSTRACT_FROM  => 'lib/Sdict.pm',
				AUTHOR         => 'Alexey Semenoff [http://swaj.net]') : () ),
);


__END__
