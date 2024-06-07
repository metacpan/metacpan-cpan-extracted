use utf8;
use strict;
use warnings;

use MsOffice::Word::Template;
use Test::More;


my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

(my $dir = $0) =~ s[tt2.t$][];
$dir ||= ".";
my $template_file = "$dir/etc/tt2_template.docx";

diag( "Testing MsOffice::Word::Template $MsOffice::Word::Template::VERSION, Perl $], $^X" );

my $template = MsOffice::Word::Template->new(
  docx         => $template_file,
  engine_class => 'TT2',
  engine_args  => [INCLUDE_PATH => "$dir/etc"],
 );

$template->engine->TT2->context->define_vmethod(list => map_field => sub {
    my ($list, $key) = @_;
    my @map = map {$_->{$key}} @$list;
    return \@map;
  });



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
like $xml, qr[toto</w:t></w:r></w:p></w:tc>],                    "toto in first table row";
like $xml, qr[<w:bookmarkStart w:id="100" w:name="bkm1"/>],      "bookmark";
like $xml, qr[<w:hyperlink w:anchor="bkm2">],                    "hyperlink";
like $xml, qr[inserted content],                                 "inserted content";
like $xml, qr[imported block N° </w:t></w:r><w:r><w:t>2],        "imported block";


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

like $xml, qr[Hello, </w:t></w:r><w:r><w:t>FOLLONICA</w:t></w:r>], "Follonica";
like $xml, qr[tata</w:t></w:r></w:p></w:tc>],                      "tata in first table row";

$new_doc->save_as("tt2_result2.docx")  if $do_save_results;


done_testing;

__END__
[Template::Context] process([ Template::Document=HASH(0x27569c3eae8) ], HASH(0x27569c3e530), <unlocalized>)
[Template::Context] template(Template::Document=HASH(0x27569c3eae8))
[Template::Context] process([ field ], HASH(0x27569c62ce0), <unlocalized>)
[Template::Context] template(field)
[Template::Context] looking for block [field]
file error - content is undefined

Compilation exited abnormally with code 25 at Tue Jun  4 20:59:55
