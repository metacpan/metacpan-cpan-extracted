use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

(my $dir = $0) =~ s[msoffice-word-surgeon.t$][];
$dir ||= ".";
my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

diag( "Testing MsOffice::Word::Surgeon $MsOffice::Word::Surgeon::VERSION, Perl $], $^X" );

my $surgeon = MsOffice::Word::Surgeon->new($sample_file);

$surgeon->part($_)->replace(qr/\bPage\b/ => sub {"Pagina"}, keep_xml_as_is => 1) for $surgeon->headers;


my $plain_text = $surgeon->plain_text;
like $plain_text, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "plain text";


like $plain_text, qr/1st/, "found 1st";
like $plain_text, qr/2nd/, "found 2nd";
like $plain_text, qr/paragraph\ncontains a soft line break/, "soft line break";

$surgeon->all_parts_do(cleanup_XML => (no_caps => 1));

my $contents = $surgeon->contents;
like $contents, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "XML after merging runs";


like $contents,   qr/somme de 1'200/,                             "do not remove runs containing '0'";
like $contents,   qr/SMALL &amp; CAPS LTD/,                       "w:caps preserves HTML entities";
unlike $contents, qr/bookmarkStart/,                              "remove bookmarks (no markup)";
unlike $contents, qr/_GoBack/,                                    "remove bookmarks (no _GoBack)";
like $contents,   qr/Condamne SMALL/,                             "remove bookmarks (contents preserved)";
like $contents,   qr/do you prefer Foo \? Really \?/,             "ASK field (1/2)";
like $contents,   qr/like this : Foo \?\B/,                       "ASK field (2/2)";
like $contents,   qr/soft hyphens that should really be removed/, "soft hyphens";

my $new_xml = $surgeon->replace(qr/\bMsWord\b/,
                                sub {"Microsoft Word"},
                               );
like $new_xml, qr/edited in Microsoft Word/,                      "after replace";

$surgeon->contents($new_xml);
$plain_text = $surgeon->plain_text;
my ($test_tabs) = $plain_text =~ /(\n.*?TAB.*)/;
like $test_tabs, qr/starts\twith an\tinitial TAB, and also has\tmany internal TABS/,
                                                                  "TABS were preserved";


is_deeply [$surgeon->headers], [qw/header1 header2 header3/],     "headers";
is_deeply [$surgeon->footers], [qw/footer1 footer2 footer3/],     "footers";


$surgeon->all_parts_do(replace => qr/\bSurgeon\b/ => sub {"Physician"});



# use Path::Tiny;
# my $img = path("d:/temp/foo.png")->slurp_raw;
# my $rId = $surgeon->document->add_image($img);
# warn "created rId $rId\n";


$surgeon->save_as("surgeon_result.docx")  if $do_save_results;

done_testing();
