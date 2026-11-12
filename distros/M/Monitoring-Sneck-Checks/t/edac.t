#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::edac;

local $Monitoring::Sneck::Checks::base::OS = 'linux';
my $data = $FindBin::Bin . '/data/edac';
my $run  = sub {
	my ( $tree, @args ) = @_;
	local $Monitoring::Sneck::Checks::edac::EDAC = $data . '/' . $tree;
	return Monitoring::Sneck::Checks->run( check => 'edac', args => \@args );
};

is(
	$run->('ok')->{stdout},
	"EDAC OK - 2 memory controllers, 0 corrected, 0 uncorrected | corrected=0;0;;0 uncorrected=0;;0;0\n"
		. "mc0 Skylake Socket#0 IMC#0, 65536 MB, 0 corrected, 0 uncorrected\n"
		. "mc1 Skylake Socket#1 IMC#0, 65536 MB, 0 corrected, 0 uncorrected\n",
	'no errors'
);
is(
	$run->('errors')->{stdout},
	"EDAC CRITICAL - 2 memory controllers, 4 corrected, 1 uncorrected,"
		. " CPU_SrcID#0_MC#0_Chan#1_DIMM#0 1 corrected, CPU_SrcID#0_MC#0_Chan#5_DIMM#0 2 corrected,"
		. " mc0 no DIMM 1 corrected, mc1 rank0 1 uncorrected | corrected=4;0;;0 uncorrected=1;;0;0\n"
		. "mc0 Skylake Socket#0 IMC#0, 65536 MB, 4 corrected, 0 uncorrected\n"
		. "mc1 ie31200, 16384 MB, 0 corrected, 1 uncorrected\n",
	'corrected and uncorrected, by DIMM'
);
is( $run->( 'errors', '-w', '10' )->{code}, 2, 'uncorrected is CRITICAL whatever --warning is' );
like( $run->( 'errors', '-w', '10' )->{stdout}, qr/ \| corrected=4;10;;0 /, '--warning in the perfdata' );
is( $run->('none')->{stdout},         "EDAC OK - no EDAC memory controllers\n",      'no controllers' );
is( $run->('missing')->{stdout},      "EDAC OK - no EDAC memory controllers\n",      'no EDAC at all' );
is( $run->( 'none', '-r' )->{stdout}, "EDAC WARNING - no EDAC memory controllers\n", 'no controllers, --required' );
is(
	$run->('broken')->{stdout},
	'EDAC UNKNOWN - can not read the counts of ' . $data . "/broken/mc/mc0\n",
	'counts not there'
);
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	like( $run->('ok')->{combined}, qr/not supported on freebsd/, 'not Linux' );
}

done_testing();
