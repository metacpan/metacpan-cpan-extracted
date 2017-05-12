
use Test::More tests => 6;

BEGIN { use_ok('Spreadsheet::ParseExcel::Stream') };

my $xls = Spreadsheet::ParseExcel::Stream->new("t/test.xls");
ok($xls, 'Created xls object');

my %data;
my $cnt;
while ( my $sheet = $xls->sheet() ) {
  # Skip first sheet
  next unless $cnt++;
  my $name = $sheet->name();
  while ( my $row = $sheet->row() ) {
    push @{$data{$name}}, [ @$row ];
  }
}

ok(%data, 'Got data');

my @sheets = keys %data;
my $sheet_cnt = @sheets;
is($sheet_cnt, 1, 'Only one sheet');

my $sheet1 = $data{"Sheet 1"};
is($sheet1, undef, 'No first sheet');

my $sheet2 = $data{"Sheet 2"};
is_deeply($sheet2, [[qw(1 2 3)],[qw(4 5 6)]], 'Second sheet OK');
