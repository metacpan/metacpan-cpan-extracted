use ExtUtils::MakeMaker;
require "./pdlmaker.plm";
pdlmaker_init();

##-- preqrequistes (for PREREQ_PM)
my %prereq = (
	      'PDL' => 0, #'2.4.2',
	      'PDL::VectorValued' => '1.0.4',
	      'Test::More' => 0,
	      'File::Basename' => 0,
	     );

##-- read in user variables
do "./Config.PL";
die "$0: reading './Config.PL' failed: $@" if ($@);

##-- put 'realclean_files' in a variable: avoid MakeMaker puking with:
##     ERROR from evaluation of .../ccsutils/Makefile.PL:
##     Modification of a read-only value attempted at /usr/share/perl/5.8/Carp/Heavy.pm line 45.
my $realclean_files = join(' ',
			   qw(*~ *.tmp),
			   (-e 'README.rpod' ? qw(README.txt README.html) : qw()),
			   (-e 'Config.PL' ? qw(CCS/Config.pm) : qw()),
			  );
WriteMakefile(
	      NAME   =>'PDL::CCS',
	      AUTHOR => 'Bryan Jurish',
	      ABSTRACT =>'Sparse N-dimensional PDLs with compressed column storage',
	      ##
	      VERSION_FROM => 'CCS.pm',
	      LICENSE => 'perl',
	      ##
	      #PM => { (map {$_=>"\$(INST_LIBDIR)/CCS/$_"} <*.pm>), },
	      DIR =>[
		     'CCS',
		    ],
	      realclean=>{ FILES=>$realclean_files, },
	      PREREQ_PM => {%prereq},
	      CONFIGURE_REQUIRES => {
				     %prereq,
				     'ExtUtils::MakeMaker'=>0,
				     'Data::Dumper' => 0,
				    },
	      ##
	      META_MERGE => {
			     "meta-spec" => { version => 2 },
			     resources => {
					   repository => {
							  url => 'git://github.com/moocow-the-bovine/PDL-CCS.git',
							  type => 'git',
							  web => 'https://github.com/moocow-the-bovine/PDL-CCS',
							 },
					  },
			    },
	     );

##-- avoid applying 'processPL' rules to 'Config.PL'
sub MY::processPL { return ''; }
