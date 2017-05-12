package PDF::Burst;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $errstr $BURST_METHOD @BURST_METHODS %BURST_METHOD $DEBUG);
@ISA = qw/Exporter/;
@EXPORT_OK = qw/pdf_burst pdf_burst_CAM_PDF pdf_burst_PDF_API2 pdf_burst_pdftk/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.20 $ =~ /(\d+)/g;
%EXPORT_TAGS  = ( all => \@EXPORT_OK );
use Exporter;
use File::Which;
use Carp;
sub errstr;
sub errstr { $errstr =$_[0]; 1 }
sub debug { $DEBUG and warn(" # ".__PACKAGE__.", @_\n"); 1 }

%BURST_METHOD = (
   CAM_PDF  => \&pdf_burst_CAM_PDF,
   PDF_API2 => \&pdf_burst_PDF_API2,
   pdftk    => \&pdf_burst_pdftk,
);
@BURST_METHODS= keys %BURST_METHOD;
$BURST_METHOD ||= 'CAM_PDF';

  #*pdf_burst = \&pdf_burst_CAM_PDF;
# *pdf_burst = \&pdf_burst_PDF_API2;


sub pdf_burst { &{$BURST_METHOD{$BURST_METHOD}}(@_) }


sub _args {
   my ($_path, $groupname, $_abs_loc)= @_;
   $_path or croak('missing args');

   my($abs, $abs_loc, $filename, $filename_only, $ext ) = _path_segments($_path)
      or warn("Cant make sense of path segments for '$_path'")
      and return;
   
   if ($_abs_loc){
      -d $_abs_loc 
         or $errstr="argument $_abs_loc abs loc not on disk" 
         and return;
      $abs_loc = $_abs_loc;
   }
   

   $groupname ||= $filename_only;
   $groupname=~/\w/ 
      or warn("groupname '$groupname' makes no sense.")
      and return;

   $ext=~/\.pdf$/i 
      or $errstr = "$abs not pdf?"
      and return;
   
   ### $abs
   ### $abs_loc
   ### $filename
   ### $filename_only
   ### $ext
   
   return ($abs,$abs_loc,$filename,$filename_only, $ext, $groupname);
}



# there HAS to be a more effective way of using CAM::PDF than to instance
# each time for each page from original doc!!1
sub pdf_burst_CAM_PDF {

   my ($abs,$abs_loc,$filename,$filename_only, $ext, $groupname) = _args(@_)
      or return;


   my @abs_page_files;

   require CAM::PDF;
   my $pdfold = CAM::PDF->new($abs)
      or $errstr="CAM_PDF: could not open $abs"
      and return;

   my $pagecount = $pdfold->numPages;
   debug("CAM_PDF: pagecount $pagecount");
   undef $pdfold;


   if ( $pagecount == 1 ){
      my $abs_page = "$abs_loc/$groupname\_page_0001$ext";
      require File::Copy;
      unlink $abs_page;
      File::Copy::cp($abs, $abs_page) 
         or $errstr="CAM_PDF: cant copy $abs to $abs_page, $!" 
         and return;
      return ($abs_page);
   }
   elsif( $pagecount == 0 ){
      $errstr="CAM_PDF: file $abs has no pages ?!";
      return ();
   }


   for my $index ( 0 .. ( $pagecount - 1 ) ){ 

      my $index_human = sprintf '%04d', ($index + 1);
      ### $index_human
      ### $index

      my $abs_page = "$abs_loc/$groupname\_page_$index_human$ext";
      debug("CAM_PDF: abs page will be: '$abs_page'.. ");



      my $pdf = CAM::PDF->new($abs) or confess("Could not CAM::PDF:: new '$abs'");
      debug("CAM_PDF: instanced CAM::PDF, will call extractPages() .. ");

      $pdf->extractPages($index + 1); # discard all but page x

      debug("CAM_PDF: calling cleansave().. ");
      $pdf->cleansave; # rebuild pdf data
      $pdf->output($abs_page);

      -f $abs_page 
         or $errstr= "CAM_PDF: could not save? !-f $abs_page"
         and return;

      push @abs_page_files, $abs_page;
      
   }
   
   return @abs_page_files;
}

sub _path_segments {
   my $_abs = shift;
   $_abs or croak('missing arg');

   require Cwd;
   my $abs = Cwd::abs_path($_abs) 
      or $errstr="$_abs not on disk? cant resolve with Cwd::abs_path"
      and warn("$_abs not on disk")
      and return;
   
   -f $abs 
      or $errstr="Path $abs not on disk." 
      and warn("path $abs not on disk")
      and return;

   $abs=~/^(.+)\/+([^\/]+)(\.\w{1,5})$/i 
      or $errstr="cant match abs loc and filename into '$abs'"
      and return;
      
   my ($abs_loc, $filename_only, $ext, $filename) = ( $1, $2, $3, $2.$3 );

   return($abs, $abs_loc,$filename,$filename_only,$ext);
}


sub pdf_burst_PDF_API2 {
   my ($abs,$abs_loc,$filename,$filename_only, $ext, $groupname) = _args(@_)
      or return;

   my @abs_pages;

   require PDF::API2;
   my $pdf_src = PDF::API2->open($abs);
   my $pagecount = $pdf_src->pages;
 
   if ( $pagecount == 1 ){
      my $abs_page = "$abs_loc/$groupname\_page_0001$ext";
      require File::Copy;
      unlink $abs_page;
      unless( File::Copy::cp($abs, $abs_page) ){
         $errstr ="PDF_API2: cant copy $abs to $abs_page, $!";
         return;
      }
      return ($abs_page);
   }
   elsif( $pagecount == 0 ){
      $errstr="PDF_API2: file $abs has no pages ?!";
      return ();
   }  

   for my $i ( 1 .. $pagecount ){
      my $pdf_out = sprintf "$abs_loc/$groupname\_page_%04d$ext", $i;
      debug("PDF_API2: $pdf_out");

      my $pdf;
      
      unless ( $pdf = PDF::API2->new ){
         $errstr="PDF_API2: cant instance PDF::API";
         return;
      }

      unless( $pdf->importpage( $pdf_src, $i )){
         $errstr="PDF_API2: cannot import page, pdf error?";
         return;
      }
      
      $pdf->saveas( $pdf_out );
      push @abs_pages, $pdf_out;

   }
   return @abs_pages;
}

sub pdf_burst_pdftk {
   my ($abs,$abs_loc,$filename,$filename_only, $ext, $groupname) = _args(@_)
      or return;
   
   no warnings;

   my @abs_pages;
   
   my $bin = File::Which::which('pdftk')
      or $errstr="pdftk: Can't find which pdftk."
      and return;

   # HACK #
   # have to be in cwd to be able to get doc_dat.txt later
   # pdftk will spit out doc_dat.txt to the cwd, must be set with chdir
   require Cwd;
   my $cwd = Cwd::cwd(); # so we can come back later.
   chdir $abs_loc;

   my @args = ( $bin, $abs, 'burst', 'output', "$abs_loc/$groupname\_page_%04d.pdf");
   system(@args) == 0 
      or $errstr="pdftk: fails: '@args'"
      and return;
   


   opendir(DIR, $abs_loc) 
      or $errstr="pdftk: can't open $abs_loc, $!" 
      and return;

   @abs_pages = map { "$abs_loc/$_" } 
      sort grep { m/$groupname\_page\_\d+\.pdf$/i } readdir DIR;
   closedir DIR;
   
   my $pgcount = scalar @abs_pages;

   # HACK ########################################################
   # if there is a ./doc_dat.txt file
   # test it against what we have for page count
   my $doc_dat = "$abs_loc/doc_data.txt";
   if ( my $dat = _pdf_burst_doc_dat_href($doc_dat) ){     

      if ( defined $dat->{NumberOfPages} ){
         
         if( $pgcount != $dat->{NumberOfPages} ){
            warn("We burst $abs into $pgcount docs, but pdftk doc_dat.txt says we are supposed to have $dat->{NumberOfPages} pages!");
         }

         if ($pgcount < $dat->{NumberOfPages}){
            warn("docs count is less than the number of pages pdftk says we should have.");

         }
         elsif( $pgcount > $dat->{NumberOfPages} ){
            warn("docs count is higher than the number of pages pdftk says we should have. Will shorten list.");
            @abs_pages = @abs_pages[0 .. ( $dat->{NumberOfPages} - 1 )];
         }
         else {
            debug("Checked with pdftk doc_dat.txt, correct number of pages.");
         }
      }
      else {
         warn("did not have 'NumberOfPages' in $doc_dat, different version of pdftk? Notify PDF::Burst AUTHOR");
      }
   }
   else {
      debug("got no doc_data.txt");
   }


   # HACK
   # go back to what it was
   chdir $cwd;


   debug($_) for @abs_pages;

   return @abs_pages;
}



# return hash ref
sub _pdf_burst_doc_dat_href {
   # this is tricky, doc data will reside wherever the heck our cwd is


   my $doc_dat = shift;
   $doc_dat or croak("missing arg");
   -f $doc_dat or return;

   debug("had '$doc_dat' file on disk");
   
   my %dat;
   
   open(FILE,'<',$doc_dat) 
      or warn("Cannot open '$doc_dat' for reading, $!")
      and return;
   while(my $line= <FILE>){
      chomp $line;
      $line=~/^(\w+)\W+(.+)$/ 
         or warn("Cant make out line '$line' into key val pair")
         and next;
      $dat{$1}= $2;
   }
   close FILE;
   
   defined %dat or warn("had nothing in '$doc_dat'?") and return;
   return \%dat;
}



1;





