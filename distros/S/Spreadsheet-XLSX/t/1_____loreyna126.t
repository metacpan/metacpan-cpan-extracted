use Test::More tests => 3;

BEGIN {

	use Spreadsheet::XLSX;
	use warnings;
	
	my $fn = __FILE__;
	
	$fn =~ s{t$}{xlsx};

	my $excel = Spreadsheet::XLSX -> new ($fn);
			
	ok (@{$excel -> {Worksheet}} == 3);	
	ok ($excel -> {Worksheet} -> [0] -> {Name} eq 'POST_DSENDS');
	ok ($excel -> {Worksheet} -> [0] -> {Cells} [112] [0] -> {Val} eq 'RCS Thrust Vector Uncertainties ');

};
 