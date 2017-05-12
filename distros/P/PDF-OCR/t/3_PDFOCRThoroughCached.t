use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR::Thorough::Cached;
use Cwd;

mkdir '/tmp/PDF-OCR-Thorough-Cached';

opendir(DIR, cwd().'/t');
my @pdfs = map {cwd()."/t/$_" } grep { /\.pdf$/ } readdir DIR;
closedir DIR;


for (@pdfs){
	my $abs_pdf = $_;
   print STDERR " - abs: $abs_pdf\n";
	my $p = new PDF::OCR::Thorough::Cached($abs_pdf);
	
	# abs pages

	my $text = $p->get_text;
   

   my $abs_cached = $p->abs_cached;
   print STDERR "abs cached:  $abs_cached \n";
   ok($text);
   print STDERR "\n--\n\n";
}



