use Test::More tests => 10;

BEGIN {

	use Spreadsheet::XLSX;
	use warnings;
	
	my $fn = __FILE__;
	$fn =~ s{t$}{xlsx};

	my $excel = Spreadsheet::XLSX->new($fn);
    my $cells = $excel->{Worksheet}[0]{Cells};
	ok ($cells->[0][0]->value() eq '2015-12-31',    'formatted date');
	ok ($cells->[0][1]->value() eq '23:59',         'formatted time');
    ok ($cells->[0][2]->value() eq '1.12',         'formatted default numeric');
    ok ($cells->[0][2]->unformatted() eq '1.125',   'unformatted default numeric');
    ok ($cells->[0][3]->value() eq '1.12',          'formatted 2-digit numeric');
    ok ($cells->[0][3]->unformatted() eq '1.125',   'unformatted 2-digit numeric');
    ok ($cells->[0][4]->value() eq 'Test',          'formatted default text');
    ok ($cells->[0][4]->unformatted() eq 'Test',    'unformatted default text');
    ok ($cells->[0][5]->value() eq '1.2345',        'formatted number in text field');
    ok ($cells->[0][5]->unformatted() eq '1.2345',  'unformatted number in text field');
};
 
