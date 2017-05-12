
use Test::More tests => 5;

BEGIN { use_ok('Spreadsheet::ParseExcel::Stream') };

my $xls = Spreadsheet::ParseExcel::Stream->new("t/test_nulls.xls");
ok($xls, 'Created xls object');

my %data;
while ( my $sheet = $xls->sheet() ) {
  my $name = $sheet->name();
  while ( my $row = $sheet->row() ) {
    push @{$data{$name}}, [ @$row ];
  }
}

ok(%data, 'Got data');

my $sheet1 = $data{"Sheet 1"};
is_deeply($sheet1, [[undef, qw(B C D)]], 'First sheet OK');

my $sheet2 = $data{"Sheet 2"};
is_deeply($sheet2, [["A", undef, qw(C D)]], 'Second sheet OK');
