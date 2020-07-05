use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

(my $dir = $0) =~ s[msoffice-word-surgeon.t$][];

my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

diag( "Testing MsOffice::Word::Surgeon $MsOffice::Word::Surgeon::VERSION, Perl $], $^X" );


my $surgeon = MsOffice::Word::Surgeon->new($sample_file);

my $plain_text = $surgeon->plain_text;
like $plain_text, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "plain text";


$surgeon->reduce_all_noises;
$surgeon->unlink_fields;
$surgeon->merge_runs;

my $contents = $surgeon->contents;
like $contents, qr/because documents edited in MsWord often have run boundaries across sentences/,
  "XML after merging runs";


my $new_xml = $surgeon->replace(qr/\bMsWord\b/,
                                sub {"Microsoft Word"},
                               );

like $new_xml, qr/edited in Microsoft Word/,  "after replace";

done_testing();

# $surgeon->contents($new_xml);
# print $surgeon->indented_contents;

# $surgeon->save_as("foo.docx");
