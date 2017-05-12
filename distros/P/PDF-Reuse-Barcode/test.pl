use Test;
BEGIN { plan tests => 15 };
use PDF::Reuse;
ok(1);
use GD::Barcode;
ok(2);
ok(find('GD::Barcode::Code39'));
ok(find('GD::Barcode::COOP2of5'));
ok(find('GD::Barcode::EAN13'));
ok(find('GD::Barcode::EAN8'));
ok(find('GD::Barcode::IATA2of5'));
ok(find('GD::Barcode::Industrial2of5'));
ok(find('GD::Barcode::ITF'));
ok(find('GD::Barcode::Matrix2of5'));
ok(find('GD::Barcode::NW7'));
ok(find('GD::Barcode::QRcode'));
ok(find('GD::Barcode::UPCA'));
ok(find('GD::Barcode::UPCE'));
ok(find('Barcode::Code128'));
use PDF::Reuse::Barcode;
ok(14);

sub find
{  $modul = shift;
   my $status = '';
   eval "use $modul;";
   if ($@)
   {  print STDERR "Can't find $modul - can't produce those barcodes \n";
   }
   else
   {  $status = "$modul found";
   }
   return $status;
}

