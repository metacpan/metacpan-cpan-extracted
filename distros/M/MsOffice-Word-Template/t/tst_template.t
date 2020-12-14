use strict;
use warnings;
use MsOffice::Word::Surgeon;
use MsOffice::Word::Template;
use Test::More;


(my $dir = $0) =~ s[tst_template.t$][];
$dir ||= ".";
my $template_file = "$dir/etc/tst_template.docx";

diag( "Testing MsOffice::Word::Template $MsOffice::Word::Template::VERSION, Perl $], $^X" );

my $template = MsOffice::Word::Template->new($template_file);

my %data = (
  foo => 'FOFOLLE',
  bar => 'WHISKY',
  list => [ {name => 'toto',   value => 123},
            {name => 'blublu', value => 456},
            {name => 'zorb',   value => 987},
           ],
);
my $new_doc = $template->process(\%data);
my $xml = $new_doc->contents;

like $xml, qr[Hello, </w:t></w:r><w:r><w:t>FOFOLLE</w:t></w:r>], "Foo";
like $xml, qr[toto</w:t></w:r></w:p></w:tc>], "toto in first table row";


# $new_doc->save_as("template_result.docx");

done_testing;
