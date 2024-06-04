use strict;
use warnings;
use Test::More;
use MsOffice::Word::Surgeon;

my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

(my $dir = $0) =~ s[reveal_bookmarks.t$][];
$dir ||= ".";
my $sample_file = "$dir/etc/MsOffice-Word-Surgeon.docx";

my $surgeon = MsOffice::Word::Surgeon->new($sample_file);
$surgeon->document->reveal_bookmarks(color => 'cyan');

my $contents = $surgeon->contents;

like $contents,
     qr{<w:highlight w:val="cyan"/></w:rPr><w:t>&lt;nested_bookmarks_1&gt;</w:t></w:r><w:bookmarkStart},
     "bookmark start";
like $contents,
     qr{<w:bookmarkEnd w:id="\d+"/><w:r><w:rPr><w:highlight w:val="cyan"/></w:rPr><w:t>&lt;/nested_bookmarks_2&gt;</w:t></w:r>},
     "bookmark end";

$surgeon->save_as("bookmarks_revealed.docx")  if $do_save_results;

done_testing();
