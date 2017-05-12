use Test::More tests => 6;

BEGIN {

	use Spreadsheet::XLSX;
	use warnings;
	
	my $fn = __FILE__;
	
	$fn =~ s{t$}{xlsx};

	my $excel = Spreadsheet::XLSX -> new ($fn);
			
	ok (@{$excel -> {Worksheet}} == 4);	
	ok ($excel -> {Worksheet} -> [0] -> {Name} eq 'Tabelle1');
	ok ($excel -> {Worksheet} -> [0] -> {Cells} [0] [0] -> {Val} == 1);
	ok ($excel -> {Worksheet} -> [0] -> {Cells} [0] [1] -> {Val} == 10);
	ok ($excel -> {Worksheet} -> [0] -> {Cells} [1] [0] -> {Val} == 2);
	ok ($excel -> {Worksheet} -> [0] -> {Cells} [1] [1] -> {Val} == 20);

};
 