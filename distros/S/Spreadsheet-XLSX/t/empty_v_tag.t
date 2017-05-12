use Test::More tests => 1;
use Test::NoWarnings;

BEGIN {

	use Spreadsheet::XLSX;
	use warnings;
	
	my $fn = __FILE__;
	$fn =~ s{t$}{xlsx};

	my $excel = Spreadsheet::XLSX->new($fn);
};
