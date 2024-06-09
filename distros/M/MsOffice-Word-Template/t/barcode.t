use strict;
use warnings;
use utf8;

use MsOffice::Word::Template;
use Test::More;

SKIP: {
  eval "use GD; use Barcode::Code128; use Image::PNG::QRCode; 1"
    or skip "GD or Barcode::Code128 or Image::PNG::QRCode is not installed";

  my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

  (my $dir = $0) =~ s[barcode.t$][];
  $dir ||= ".";
  my $template_file = "$dir/etc/barcode_template.docx";

  my $template = MsOffice::Word::Template->new(docx => $template_file);


  # virtual method in TT2 for displaying a 18-digits number with intermediate
  # dots at positions 2, 4 and 10, as is usual for Swiss Post identification numbers
  $template->engine->TT2->context->define_vmethod(scalar => dotted_barcode => sub {
    my ($num) = @_;
    my @sub_nums = unpack "A2 A2 A6 A8", $num;
    my $dotted_num = join ".", @sub_nums;
    return $dotted_num;
  });


  my %data = (
    foo             => 'FOOD UNLIMITED',
    bar             => 'OPEN BAR',
    barcode_number  => 112233445566778899,
    address         => [ "Nice Templating Ltd", "123 Perl Street", "CH-1200 Genève"  ],
    barcode_number2 => 987654321987654321,
    qrcode_content  => "https://foo.bar.bie.bug.org",
  );
  my $new_doc = $template->process(\%data);

  my $xml = $new_doc->contents;

  # the only thing that can be tested automatically
  like $xml, qr[\Q11.22.334455.66778899\E], "dotted_barcode";


  # barcode and qr-code can only be tested visually by opening the .docx in MsWord
  $new_doc->save_as("barcode.docx") if $do_save_results;
}

done_testing;







