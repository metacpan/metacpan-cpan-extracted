use Test::More;
use PDFio::FFI;

my $box = PDFio::FFI::Rect->new([0.0, 0.0, 612.0, 792.0]);

my $pdf = fileCreate("myoutputfile.pdf", "2.0", $box, bless([36.0, 36.0, 576.0, 756.0], "PDFio::FFI::Rect"));
my $font = fileCreateFontObjFromBase($pdf, "Courier");
my $dict = dictCreate($pdf);

pageDictAddFont($dict, "F1", $font);
my $page = fileCreatePage($pdf, $dict);

my $caption = "Hello World";
my $tx = 300;
my $ty = 700;
contentTextBegin($page);
contentSetTextFont($page, "F1", 18.0);
contentTextMoveTo($page, $tx, $ty);
contentTextShow($page, 0, $caption);
contentTextEnd($page);
streamClose($page);
fileClose($pdf);

my $open = fileOpen("myoutputfile.pdf");

is(fileGetNumPages($open), 1);

fileClose($open);

done_testing();
