#!/usr/bin/perl
use strict;
use CAM::PDF;


my $file_in = $ARGV[0];
my $prepend = $ARGV[1];
$prepend ||= 'out';



my $pdf = CAM::PDF->new($file_in);
my $count = $pdf->numPages;
undef $pdf;

for my $i ( 0 .. ( $count - 1 )){
   my $_i = ($i+1);

   my $file_out = sprintf "%s_page_%04d.pdf", $file_in, $_i;
   # make sure it's not there
   unlink $file_out;

   
   my $pdf = CAM::PDF->new($file_in);
   $pdf->extractPages($_i);
   $pdf->cleansave;

   $pdf->output($file_out);

   print STDERR "saved $file_out\n";

}


exit;



__END__
    use CAM::PDF;
    
    my $pdf = CAM::PDF->new('test1.pdf');
    
    my $page1 = $pdf->getPageContent(1);
    [ ... mess with page ... ]
    $pdf->setPageContent(1, $page1);
    [ ... create some new content ... ]
    $pdf->appendPageContent(1, $newcontent);
    
    my $anotherpdf = CAM::PDF->new('test2.pdf');
    $pdf->appendPDF($anotherpdf);
    
    my @prefs = $pdf->getPrefs();
    $prefs[$CAM::PDF::PREF_OPASS] = 'mypassword';
    $pdf->setPrefs(@prefs);
    
    $pdf->cleanoutput('out1.pdf');
    print $pdf->toPDF();
