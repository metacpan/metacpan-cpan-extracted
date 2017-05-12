use Test::Simple 'no_plan';
use File::Which 'which';




my @bins = qw(xpdf pdfimages convert tesseract);

for my $bin (@bins){
   ok( which($bin), "path to $bin found") 
      or warn("File::Which::which() cannot find path to $bin, is it installed??")
      and warn("PDF::OCR cannot be installed without $bin");

}





