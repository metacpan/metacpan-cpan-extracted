use strict;
use warnings;
use MsOffice::Word::Template;
use Test::More;


my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

(my $dir = $0) =~ s[tt2.t$][];
$dir ||= ".";
my $template_file = "$dir/etc/tt2_template.docx";

diag( "Testing MsOffice::Word::Template $MsOffice::Word::Template::VERSION, Perl $], $^X" );

my $template = MsOffice::Word::Template->new($template_file);

my %data = (
  foo => 'FOFOLLE',
  bar => 'WHISKY & <GIN>',
  list => [ {name => 'toto',   value => 123},
            {name => 'blublu', value => 456},
            {name => 'zorb',   value => 987},
           ],
);
my $new_doc = $template->process(\%data);
my $xml = $new_doc->contents;

like $xml, qr[Hello, </w:t></w:r><w:r><w:t>FOFOLLE</w:t></w:r>], "Foo";
like $xml, qr[toto</w:t></w:r></w:p></w:tc>], "toto in first table row";
$new_doc->save_as("tt2_result.docx") if $do_save_results;

# 2nd invocation to test potential caching problems
my %data2 = (
  foo => 'FOLLONICA',
  bar => 'SAMBUCA',
  list => [ {name => 'tata',   value => 123},
            {name => 'boble',  value => 456},
            {name => 'zarf',   value => 987},
           ],
);
$new_doc = $template->process(\%data2);
$xml = $new_doc->contents;

like $xml, qr[Hello, </w:t></w:r><w:r><w:t>FOLLONICA</w:t></w:r>], "Foo";
like $xml, qr[tata</w:t></w:r></w:p></w:tc>], "tata in first table row";

$new_doc->save_as("tt2_result2.docx")  if $do_save_results;


done_testing;
