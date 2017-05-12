
use Test::More tests => 5;

BEGIN { use_ok('Spreadsheet::ParseExcel::Stream') };

my $xls = Spreadsheet::ParseExcel::Stream->new("t/test.xls");
ok($xls, 'Created xls object');

my %data;
while ( my $sheet = $xls->sheet() ) {
  my $name = $sheet->name();
  while ( my $row = $sheet->next_row() ) {
    push @{$data{$name}}, [ map { $_->value() } @$row ];
  }
}

ok(%data, 'Got data');

my $sheet1 = $data{"Sheet 1"};
is_deeply($sheet1, [[qw(a b c)],[qw(d e f)]], 'First sheet OK');

my $sheet2 = $data{"Sheet 2"};
is_deeply($sheet2, [[qw(1 2 3)],[qw(4 5 6)]], 'Second sheet OK');
