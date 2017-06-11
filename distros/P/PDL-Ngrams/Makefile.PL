use ExtUtils::MakeMaker;

use lib '.'; ##-- fix RT bug #121661?
require "pdlmaker.plm";
pdlmaker_init();

##-- common prerequisites
my %prereq = (
	      'PDL' => 0,
	      'PDL::VectorValued' => '1.0.4',    ##-- for rlevec(), rleND(), vv_qsortvec(), vv_indx_sig(), vv_indx_typedef()
	      'Test::More' => 0,
	     );

##-- strange bogus cpantesters error messages
## + see http://sourceforge.net/p/pdl/mailman/message/34623263/ ("headaches with indirect PDL-related dependencies on cpantesters", 2015-11-16 13:16:44)
## + workaround: ensure working PDL::VectorValued at configure-time; return UNKNOWN otherwise
## + 'UNKNOWN' reports are pretty unsatisfying too; using Perl::Version shared $VERSION in PDL::VectorValued
##   as suggested in thread http://www.perlmonks.org/?node_id=1148116

WriteMakefile(
	      NAME         => 'PDL::Ngrams',
	      VERSION_FROM => 'Ngrams/ngutils.pd',
	      ABSTRACT     => 'N-Gram utilities for PDL',
	      AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
	      LICENSE      => 'perl',
	      PREREQ_PM    => {%prereq},
	      CONFIGURE_REQUIRES => {%prereq},
	      realclean => {
			    FILES => '*~ *.tmp README.txt',
			   },
	     );
