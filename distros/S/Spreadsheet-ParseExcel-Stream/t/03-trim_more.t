
use Test::More tests => 5;

BEGIN { use_ok('Spreadsheet::ParseExcel::Stream') };

my $xls = Spreadsheet::ParseExcel::Stream->new("t/test_trim.xls", {TrimEmpty => 1});
ok($xls, 'Created xls object');

my %data;
while ( my $sheet = $xls->sheet() ) {
  my $name = $sheet->name();
  while ( my $row = $sheet->row() ) {
    push @{$data{$name}}, [ @$row ];
  }
}

ok(%data, 'Got data');

my $sheet1 = $data{"Sheet1"};
is_deeply($sheet1, [[qw(A B C)],[undef, qw(A B C)],[undef, undef, qw(A B C)],[undef, qw(A B C)]], 'First sheet OK');

my $sheet2 = $data{"Sheet2"};
is_deeply($sheet2, [[qw(A B C)],[undef, undef, qw(A B C)],[undef, undef, undef, qw(A B C)],[undef, undef, qw(A B C)]], 'Second sheet OK');
