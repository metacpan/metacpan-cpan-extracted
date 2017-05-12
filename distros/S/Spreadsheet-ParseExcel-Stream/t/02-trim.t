
use Test::More tests => 5;

BEGIN { use_ok('Spreadsheet::ParseExcel::Stream') };

my $xls = Spreadsheet::ParseExcel::Stream->new("t/test_nulls.xls", {TrimEmpty => 1});
ok($xls, 'Created xls object');

my %data;
while ( my $sheet = $xls->sheet() ) {
  my $name = $sheet->name();
  while ( my $row = $sheet->row() ) {
    push @{$data{$name}}, [ @$row ];
  }
}

ok(%data, 'Got data');

# This spreadsheet was created with S:WE
# So all leading empty columns will be trimmed
my $sheet1 = $data{"Sheet 1"};
is_deeply($sheet1, [[qw(B C D)]], 'First sheet OK');

my $sheet2 = $data{"Sheet 2"};
is_deeply($sheet2, [["A", undef, qw(C D)]], 'Second sheet OK');
