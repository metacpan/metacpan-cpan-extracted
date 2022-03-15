use ExtUtils::MakeMaker;

#@MY::pdpm = qw(Utils/Utils.pm);
require "./pdlmaker.plm";
pdlmaker_init();

WriteMakefile(
	      NAME         => 'PDL::VectorValued',
	      VERSION_FROM => 'VectorValued.pm',
	      ABSTRACT     => 'Assorted utilities for vector-valued PDLs',
	      AUTHOR       => 'Bryan Jurish',
	      LICENSE      => 'perl',
	      PREREQ_PM => {
			    PDL => 2.019, # really want 2.075 for $SIZE(N) access in RedoDimsCode for utils.pd
			    'Test::More' => 0,
			   },
	      CONFIGURE_REQUIRES => {
				     PDL => 0,
				    },
	      realclean => {
			    FILES => join(' ', qw(*~ *.tmp),(-e 'README.rpod' ? 'README.txt' : qw())),
			   },
	      META_MERGE => {
			     "meta-spec" => { version => 2 },
			     resources => {
					   repository => {
							  url => 'git://github.com/moocow-the-bovine/PDL-VectorValued.git',
							  type => 'git',
							  web => 'https://github.com/moocow-the-bovine/PDL-VectorValued',
							 },
					  },
			    },

	     );
