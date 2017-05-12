use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR::Thorough::Cached;
use Cwd;

mkdir '/tmp/PDF-OCR-Thorough-Cached';

opendir(DIR, cwd().'/t');
my @pdfs = map {cwd()."/t/$_" } grep { /\.pdf$/ } readdir DIR;
closedir DIR;



print STDER "TRYING WITH SUM .. \n\n";


for (@pdfs){
	my $abs_pdf = $_;
   print STDERR " - abs: $abs_pdf\n";

	my $p = new PDF::OCR::Thorough::Cached($abs_pdf);
   $PDF::OCR::Thorough::Cached::CACHE_BY_SUM = 1;

   my $cachefile = $p->abs_cached;
   ok($cachefile, "Cachefile is $cachefile");


   my $sum = $p->_md5sum;
   ok($sum, "sum is $sum");



	# abs pages

	my $text = $p->get_text;
   

   my $abs_cached = $p->abs_cached;
   print STDERR "abs cached:  $abs_cached \n";
   ok($text);
   print STDERR "\n--\n\n";
}












