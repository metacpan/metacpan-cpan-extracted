#!perl
use utf8;
use Test::More;
use lib "../lib";
use MIME::QuotedPrint qw/encode_qp/;
use Encode            qw/encode_utf8/;
use MsOffice::Word::HTML::Writer;

my $doc = MsOffice::Word::HTML::Writer->new(
  title => "Demo",
  WordDocument => {View => 'Print',
                   Compatibility => {DoNotExpandShiftReturn => ""} },
 );
$doc->write("hello, world");
my $br = $doc->page_break;
$doc->write($br . "new page after manual break");
$doc->create_section(new_page => 'right');
$doc->write("new page after right section break");

$doc->create_section(new_page => 1);
$doc->write("new page after normal section break");

my $txt = "this <b>is</b> an <em>April 1<sup>st</sup> joke</em>";
$doc->write($doc->quote($txt, 'true')); # prevent HTML entity encoding

$doc->write("27 Ocak 1756 yılında Salzbug'da doğmuş, 5 Aralık 1791 yılında Viyana'da ölmüştür");

my $content = $doc->content;

like($content, qr(<w:View>Print</w:View>), "View => print");
like($content, qr(<w:Compatibility><w:DoNotExpandShiftReturn />),
                    "Compatibility => DoNotExpandShiftReturn");

my @break_right = $content =~ /page-break-before:right/g;
is(scalar(@break_right), 1, "page break:right");


like($content, qr(<em>April 1<sup>st</sup> joke</em>), 
    "prevent HTML entity encoding");

my $utf8_word = encode_qp(encode_utf8('doğmuş'), '');
like($content, qr/$utf8_word/, 'UTF8 support');

done_testing;

# $doc->save_as("01_word_document.doc");
