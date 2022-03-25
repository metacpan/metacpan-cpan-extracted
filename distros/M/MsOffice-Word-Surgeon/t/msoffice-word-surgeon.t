use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

(my $dir = $0) =~ s[msoffice-word-surgeon.t$][];
$dir ||= ".";
my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

diag( "Testing MsOffice::Word::Surgeon $MsOffice::Word::Surgeon::VERSION, Perl $], $^X" );

my $surgeon = MsOffice::Word::Surgeon->new($sample_file);

my $plain_text = $surgeon->plain_text;
like $plain_text, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "plain text";


like $plain_text, qr/1st/, "found 1st";
like $plain_text, qr/2nd/, "found 2nd";
like $plain_text, qr/paragraph\ncontains a soft line break/, "soft line break";

$surgeon->cleanup_XML(no_caps => 1);

my $contents = $surgeon->contents;
like $contents, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "XML after merging runs";


like $contents,   qr/somme de 1'200/,                   "do not remove runs containing '0'";
like $contents,   qr/SMALL &amp; CAPS LTD/,             "w:caps preserves HTML entities";
unlike $contents, qr/bookmarkStart/,                    "remove bookmarks (no markup)";
unlike $contents, qr/_GoBack/,                          "remove bookmarks (no _GoBack)";
like $contents,   qr/Condamne SMALL/,                   "remove bookmarks (contents preserved)";
like $contents,   qr/do you prefer Foo \? Really \?/,   "ASK field (1/2)";
like $contents,   qr/like this : Foo \?\B/,             "ASK field (2/2)";
like $contents,   qr/soft hyphens that should really be removed/, "soft hyphens";



my $new_xml = $surgeon->replace(qr/\bMsWord\b/,
                                sub {"Microsoft Word"},
                               );
like $new_xml, qr/edited in Microsoft Word/,  "after replace";

$surgeon->contents($new_xml);
$plain_text = $surgeon->plain_text;
my ($test_tabs) = $plain_text =~ /(\n.*?TAB.*)/;
like $test_tabs, qr/starts\twith an\tinitial TAB, and also has\tmany internal TABS/,
  "TABS were preserved";



done_testing();
