#!perl

use Test::More tests => 4;

use MsOffice::Word::HTML::Writer;

my $doc = MsOffice::Word::HTML::Writer->new(
  title => "Demo",
  WordDocument => {View => 'Print',
                   Compatibility => {DoNotExpandShiftReturn => ""} },
 );
$doc->write("hello, world");
my $br = $doc->page_break('right');
$doc->write($br . "new page after manual break");
$doc->create_section(new_page => 'right');
$doc->write("new page after section break");

my $txt = "this <b>is</b> an <em>April 1<sup>st</sup> joke</em>";
$doc->write($doc->quote($txt, 'true')); # prevent HTML entity encoding

my $content = $doc->content;

like($content, qr(<w:View>Print</w:View>), "View => print");
like($content, qr(<w:Compatibility><w:DoNotExpandShiftReturn />),
                    "Compatibility => DoNotExpandShiftReturn");

my @break_right = $content =~ /page-break-before:right/g;
is(scalar(@break_right), 2, "page break:right");


like($content, qr(<em>April 1<sup>st</sup> joke</em>), 
    "prevent HTML entity encoding");
