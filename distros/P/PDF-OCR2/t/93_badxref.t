use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR2::Base ':all';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

$PDF::OCR2::Base::DEBUG = 1;
ok( 1, 'started');

my $badxref_cannot_be_repaired= $cwd.'/t/problemdocs/dev.bad_xref.pdf';
my $badxref= $cwd.'/t/problemdocs/dev.bad_xref_can_be_repaired.pdf';

my $goodxref = $cwd.'/t/leodocs/hdreceipt.pdf';

-f $badxref or warn("missing badxref file $badxref") and exit;

-f $goodxref or die;


ok_part('good pdf');
ok( check_pdf($goodxref), 'check_pdf() a good file');



ok_part("bad pdf");
ok( ! check_pdf($badxref), 'check_pdf() a bad file');





ok_part('can we repair?');
my $tmp = repair_xref($badxref);
ok( $tmp, "repair_xref() $tmp");


ok_part('test with flags..');
$PDF::OCR2::Base::CHECK_PDF = 0;
ok( get_abs_pdf($badxref), 'get_abs_pdf() with CHECK_PDF off works');

warn("\n");
$PDF::OCR2::Base::CHECK_PDF = 1;
ok(!  get_abs_pdf($badxref), 'get_abs_pdf() with CHECK_PDF on does not work');



ok_part("bogus pdf..");

ok( ! get_abs_pdf('./w8yaq83ygbogus'), 'get_abs_pdf() on bogus fails');















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}

