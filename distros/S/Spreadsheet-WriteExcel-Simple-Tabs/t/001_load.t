# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 18;

BEGIN { use_ok( 'Spreadsheet::WriteExcel::Simple::Tabs' ); }

my $ss = Spreadsheet::WriteExcel::Simple::Tabs->new ();
isa_ok ($ss, 'Spreadsheet::WriteExcel::Simple::Tabs');
isa_ok ($ss->book, 'Spreadsheet::WriteExcel');
my @sheet=();
@sheet=$ss->book->sheets;
is(scalar(@sheet), 0, 'sheets');

$ss->add(T1 => [ [qw{a b c d}], [1,2,3,4], [5,6,7,8] ],
         T2 => [ ["a"]        ,       [1],       [2] ],
         T3 => [ ["b"]        ,       [3],       [4] ],
         T4 => [ ["c"]        ,       [5],       [6] ],
        );
@sheet=$ss->book->sheets;
is(scalar(@sheet), 4, 'sheets');
isa_ok($sheet[0], "Spreadsheet::WriteExcel::Worksheet", 'sheet');
isa_ok($sheet[1], "Spreadsheet::WriteExcel::Worksheet", 'sheet');
isa_ok($sheet[2], "Spreadsheet::WriteExcel::Worksheet", 'sheet');
isa_ok($sheet[3], "Spreadsheet::WriteExcel::Worksheet", 'sheet');
is($sheet[0]->get_name, "T1", 'sheet->get_name');
is($sheet[1]->get_name, "T2", 'sheet->get_name');
is($sheet[2]->get_name, "T3", 'sheet->get_name');
is($sheet[3]->get_name, "T4", 'sheet->get_name');
my $content=$ss->content;
my $length=length($content);

is($length > 0, 1, 'Does content have data.');

#Catch 22 for testing.  Do we test content and add all of the req for that?

my $header='';
$header=$ss->header;
is($header, "Content-type: application/vnd.ms-excel\n\n", 'header1');

$header=$ss->header(content_type=>"CT");
is($header, "Content-type: CT\n\n", 'header2');

$header=$ss->header(filename=>"FN");
is($header, qq{Content-type: application/vnd.ms-excel\nContent-Disposition: attachment; filename="FN";\n\n}, 'header3');

$header=$ss->header(filename=>"FN", content_type=>"CT");
is($header, qq{Content-type: CT\nContent-Disposition: attachment; filename="FN";\n\n}, 'header4');
