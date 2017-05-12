use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR::Thorough;
use Cwd;


$PDF::OCR::Thorough::DEBUG = 1;

opendir(DIR, cwd().'/t');
my @pdfs = map {cwd()."/t/$_" } grep { /\.pdf$/ } readdir DIR;
closedir DIR;


for (@pdfs){
	my $abs_pdf = $_;

	my $p = new PDF::OCR::Thorough($abs_pdf);
	
	# abs pages

	

	ok($p->abs_tmp_pdf,'abs tmp pdf.'. $p->abs_tmp_pdf);	

	ok($p->pages, 'pages() count');

	ok($p->abs_pages, 'abs pages');
	
	ok($p->abs_images, 'abs images, all');

	my $text = $p->get_text;

	open(FILE, ">$abs_pdf.txt");
	print FILE $text;
	close FILE;
	
	ok(-f "$abs_pdf.txt", " output saved : $abs_pdf.txt");

   
	
   my @pages = split( /\f/, $text);	

   printf STDERR "pagecount %s\n\n", scalar @pages;


}

