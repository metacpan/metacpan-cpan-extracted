#!/usr/bin/perl -T
BEGIN {$^W=0}

use lib 't';

# Should work with weird values (unlike PDF::API2).
$/ = 8;
$\ = "\7";
$, = "<";

use PDF::Tiny;

use tests 1; # page_count
my $pdf = new PDF::Tiny "t/4pages.pdf";
is page_count $pdf, 4, 'page_count';


use tests 5; # get_page
# 4pages.pdf was modified manually (in a text editor) to include "/Foo/Bar"
# in the first page’s dictionary, so that we can test which page we are
# getting without having to mess with content streams.
is PDF'Tiny'serialize($pdf->get_obj($pdf->get_page(0), "/Foo")), "/Bar",
  'get_page(0)';
is PDF'Tiny'serialize($pdf->get_obj($pdf->get_page(-4),"/Foo")), "/Bar",
  'get_page(-4)';
is PDF'Tiny'serialize($pdf->get_page(-3)),
   PDF'Tiny'serialize($pdf->get_page(1)), 'get_page(-3) eq get_page(1)';
isn't PDF'Tiny'serialize($pdf->get_page(2)),
      PDF'Tiny'serialize($pdf->get_page(1)), 'get_page(2) ne get_page(1)';
is $pdf->get_page(3)->[0], 'dict','get_page returns the right kind of obj';

use tests 1; # append
use File::Copy;
my $fn = tempfile;
copy "t/4pages.pdf", $fn;
$pdf = new PDF'Tiny $fn;
$pdf->vivify_obj('str', '/Info', '/Title')->[1] = "Tie Tool";
$pdf->append;
undef $pdf;
open fh, $fn or die $!;
binmode fh;
seek fh, $size = -s "t/4pages.pdf", 0;
read fh, $buf, (-s $fn) - $size;
$buf =~ s/ID\[\(.*?\)\]/ID[(xxx)(xxx)]/s;
is $buf, <<'e', 'append (title change)';

27 0
obj(Tie Tool)endobj
xref
0 1
0000000000 65535 f 
27 1
0000008587 00000 n 
trailer<</ID[(xxx)(xxx)]/Info
1
0
R/Prev
7749/Root
23
0
R/Size
34>>
startxref
8612
%%EOF
e

use tests 1; # append with objects deleted
my $fn = tempfile;
copy "t/4pages.pdf", $fn;
$pdf = new PDF'Tiny $fn;
my $info = $pdf->get_obj('/Info');
my $title_id = $$info[1]{Title}[1];
delete $$info[1]{Title};
$pdf->modified($title_id);
$pdf->modified("/Info");
delete $pdf->[objs]{$title_id};
$pdf->append;
#copy $fn, "$fn.pdf";
undef $pdf;
open fh, $fn or die $!;
binmode fh;
seek fh, $size = -s "t/4pages.pdf", 0;
read fh, $buf, (-s $fn) - $size;
$buf =~ s/ID\[\(.*?\)\]/ID[(xxx)(xxx)]/s;
#++$Data'Dumper'Useqq;
#use Data::Dumper; warn Dumper $buf; 
#local $\;

is $buf, <<'e','append with deletion';

1 0
obj<</AAPL:Keywords
33
0
R/Author
29
0
R/CreationDate
31
0
R/Creator
30
0
R/Keywords
32
0
R/ModDate
31
0
R/Producer
28
0
R>>endobj
xref
0 2
0000000000 65535 f 
0000008587 00000 n 
trailer<</ID[(xxx)(xxx)]/Info
1
0
R/Prev
7749/Root
23
0
R/Size
34>>
startxref
8722
%%EOF
e

use tests 1; # append with a stream added
my $fn = tempfile;
copy "t/4pages.pdf", $fn;
$pdf = new PDF'Tiny $fn;
my $root = $pdf->get_obj('/Root');
my $stream_id = $pdf->add_obj(['stream', ['flat', '<</Length 3>>'],"Bar"]);
$$root[1]{Foo} = ['ref', $stream_id];
$pdf->modified("/Root");
$pdf->append;
#copy $fn, "$fn.pdf";
undef $pdf;
open fh, $fn or die $!;
binmode fh;
seek fh, $size = -s "t/4pages.pdf", 0;
read fh, $buf, (-s $fn) - $size;
$buf =~ s/ID\[\(.*?\)\]/ID[(xxx)(xxx)]/s;

is $buf,<<'e', 'append with stream';

23 0
obj<</Foo
34
0
R/Pages
3
0
R/Type/Catalog>>endobj
34 0
obj<</Length 3>>stream
Bar
endstream endobj
xref
0 1
0000000000 65535 f 
23 1
0000008587 00000 n 
34 1
0000008642 00000 n 
trailer<</ID[(xxx)(xxx)]/Info
1
0
R/Prev
7749/Root
23
0
R/Size
35>>
startxref
8691
%%EOF
e

use tests 1; # print
my $fn = tempfile;
$pdf = new PDF'Tiny "t/4pages.pdf";
my $pgs = $pdf->get_obj('/Root','/Pages','/Kids');
@{$$pgs[1]} = $$pgs[1][0];
$pdf->get_obj('/Root','/Pages',"/Count")->[1] = 1;
$pdf->get_obj('/ID')->[1] = [(['str','xxx'])x2];
open my $out, ">", \my $output;
$pdf->print(fh=>$out);
close $out;
open $out, "t/output.pdf" or die "Cannot open t/output.pdf: $!";
binmode $out;
{
 local $/;
 is $output, <$out>, 'print';
}

use tests 2; # add_obj
ok 1;
# ~~~ See whether it reuses freed objects.
{
 # spaces.pdf has 3 objects.
 is +(my $pdf= new PDF'Tiny 't/spaces.pdf')->add_obj(['null']),
   "4 0",
   "add_obj assigns correct number";
}

use tests 2; # import_page
# extract a page. SYNOPSIS test.
{
  my $source_pdf  = new PDF::Tiny "t/4pages.pdf";
  my $new_pdf     = new PDF::Tiny version => $source_pdf->version;
  # Get just the first three
  for (0..2) {
    $new_pdf->import_page($source_pdf, $_);
  }
  open my $out, ">", \my $output;
  $new_pdf->vivify_obj('array','/ID')->[1] = [(['str','xxx'])x2];
  $new_pdf->print(fh=>$out);
#  $new_pdf->print(filename=>"foo.pdf");
  close $out;
  open $out, "t/output2.pdf" or die "Cannot open t/output2.pdf: $!";
  binmode $out;
  {
   local $/;
   is $output, <$out>, 'import_obj';
  }
}
# extract a page from a document with MediaBox specified twice, once in the
# Page object (the right size) and once in the Pages (page tree) object
# (the wrong size).
{
  my $source_pdf  = new PDF::Tiny "t/pagesize.pdf";
  (my $new_pdf     = new PDF::Tiny)->import_page($source_pdf, 0);
  like PDF'Tiny'serialize(
        $new_pdf->get_obj(qw< /Root /Pages /Kids 0 /MediaBox >)
       ),
       qr/^\[0\s+0\s+456\s+667.2]\z/,
      'import_page with two MediaBox';
}

use tests 1; # Test huge amounts of whitespace.
# t/spaces.t has 4K of whitespace in the reference to the first page.
like PDF'Tiny'serialize(
      new PDF'Tiny "t/spaces.pdf",
       ->get_obj("/Root","/Pages","/Kids",0,"/MediaBox")
     ),
     qr/^\[0\s0\s403\.440\s629\.760\]\z/, 'huge amounts of whitespace';

use tests 1; # parse_string
ok !eval { PDF'Tiny'parse_string($_="(foo"); 1 },
   'parse_string does not hang';

use tests 4; # serialize
like PDF'Tiny'serialize(PDF'Tiny'make_str('x'x8192)), qr/\nx{253}\\\n/,
    'serialization of long strings';
is PDF'Tiny'serialize(PDF'Tiny'make_str("\r\r\r")), '(\r\r\r)',
  'serialization of strings containing \r';
like PDF'Tiny'serialize(['tokens',['<'.'a'x500 .'>']]), qr/a\na/,
  'serialization of hex strings';
unlike PDF'Tiny'serialize(['flat','<'.'a'x500 .'>']), qr/a\na/,
  'serialization of flat objects leaves them alone';
  # (under the assumption that they represent already valid PDF code; this
  #  test uses invalid PDF code, since the line is too long)

use tests 2; # Test parsing of long strings.
{
 my $pdf = new PDF'Tiny "t/spaces.pdf";
 $pdf->trailer->[1]->{Info}
    ||= PDF::Tiny::make_ref($pdf->add_obj(PDF::Tiny::make_dict({})));
 $pdf->vivify_obj('str', '/Info', '/Title')->[1] = "T"x8192;
 my $fn = tempfile;
 $pdf->print(filename=>$fn);
 my $new_pdf = new PDF::Tiny $fn;
 is $new_pdf->get_obj("/Info","/Title")->[1], "T"x8192, '8K title';
 @{ $pdf->get_obj("/Info","/Title") } =
   ('flat', '<'.("a"x200 ."\n")x8 .">");
 $pdf->print(filename=>$fn);
 $new_pdf = new PDF::Tiny $fn;
 is $new_pdf->get_obj("/Info","/Title")->[1], "\xaa"x800, 'long hex title';
   
}

use tests 1; # tiny files
{
 my $fn = tempfile;
 open my $fh, ">", $fn, or die "Cannot open $fn for writing: $!";
 print $fh <<'';
%PDF-1.3
xref
0 1
0000000000 65535 f 
trailer<</Size 1>>
startxref
9
%%EOF

 close $fh;
 ok new PDF::Tiny ($fn), "tiny files";
}

use tests 1; # Acrobat 7 files (xref and obj streams)
ok new PDF'Tiny("t/7.pdf"), "PDF 1.6";

use tests 1; # Uncompressed files
ok new PDF'Tiny("t/uncompressed.pdf"), "Uncompressed streams";
