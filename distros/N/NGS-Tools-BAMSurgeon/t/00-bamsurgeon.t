### 00-test.t #############################################################################
# This file is a template for testing

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use FindBin qw($Bin);

use Test::More;

### Tests #################################################################################

# Verify that the module can be included. (BEGIN just makes this happen early)
BEGIN {use_ok('NGS::Tools::BAMSurgeon')};

# Verify some 
ok(my $bamsurgeon = NGS::Tools::BAMSurgeon->new(
	working_dir => '.',
	config => "$Bin/../share/config.yaml",
	somatic_profile => "$Bin/../share/somatic.yaml",
	germline_profile => "$Bin/../share/germ_mut.yaml",
	bam => 'test.bam',
	tumour_name => "test",
	sex => 'M',
	gpercent => 0.7,
	seed => 12345,
	minvaf => 1,
	maxvaf => 1,
	vafbeta1 => 2.0,
	vafbeta2 => 2.0,
	indel_minlen => 1,
	indel_maxlen => 90,
	indel_types => 'INS,DEL',
	sv_minlen => 3000,
	sv_maxlen => 30000,
	sv_types => 'DUP,INV',

	phasing => 0,
	redochrs => 'all'
	), "Make sure we can instantiate");

done_testing();

1;
