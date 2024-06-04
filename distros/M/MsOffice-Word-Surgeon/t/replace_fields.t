use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

(my $dir = $0) =~ s[replace_fields.t$][];
$dir ||= ".";
my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

my $surgeon = MsOffice::Word::Surgeon->new($sample_file);
$surgeon->document->reveal_fields;


my $contents = $surgeon->contents;

like $contents, qr[\{\h+TOC.*?}], "field TOC was replaced";
like $contents, qr[\{\h+ASK.*?}], "field ASK was replaced";
like $contents, qr[\{\h+REF.*?}], "field REF was replaced";

$surgeon->save_as("fields_replaced.docx")  if $do_save_results;

done_testing();

