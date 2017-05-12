package PDF::GetImages;
use strict;
use File::Which 'which';
use Carp;
require Exporter;
use Cwd;
use vars qw(@EXPORT_OK @ISA $WHICH_CONVERT $WHICH_PDFIMAGES $VERSION $DEBUG $errstr $FORCE_JPG @TRASH);
@ISA = qw(Exporter);
@EXPORT_OK = qw(pdfimages);
$VERSION = sprintf "%d.%02d", q$Revision: 1.18 $ =~ /(\d+)/g;
$FORCE_JPG=0;
$WHICH_CONVERT ||= which('convert');
$WHICH_PDFIMAGES ||= which('pdfimages')
   or croak( " is pdfimages (xpdf) installed? Cant get which() pdfimages");

sub errstr { $errstr = $_[0] if defined $_[0]; 1 }

sub debug { $DEBUG and print STDERR __PACKAGE__.", @_\n"; 1 }



sub pdfimages {
	my ($_abs_pdf,$_dir_out) = @_;
   defined $_abs_pdf or croak('missing argument');

   no warnings;
   debug("args: in '$_abs_pdf'");

   carp($_abs_pdf) if $DEBUG;

   my $cwd = Cwd::cwd();

   my $abs_pdf = Cwd::abs_path($_abs_pdf)
      or errstr("can't resolve location of '$_abs_pdf', cwd is $cwd")
      and return;
   
   -f $abs_pdf or errstr("ERROR: $abs_pdf is NOT on disk.") and return;


   $abs_pdf=~/(.+)\/([^\/]+)(\.pdf)$/i
      or errstr("$abs_pdf not '.pdf'?")
      and return;


   my ($abs_loc,$filename,$filename_only) = ($1,"$2$3",$2);
   
   my $_copied=0;
   if( $_dir_out ){ # did user specify a dir out to
      debug("have dir out arg '$_dir_out'.. ");
      my $dir_out = Cwd::abs_path($_dir_out) 
         or croak("cant resolve $_dir_out, should be able to, please notify PDF::GetImages AUTHOR");
      debug("have dir out '$_dir_out', resolved to $dir_out");

      if ($dir_out ne $abs_loc){
         debug("dir out not same as original file loc");
          -d $dir_out or croak("Dir out arg is not a dir $dir_out");

         require File::Copy;
         File::Copy::copy($abs_pdf,"$dir_out/$filename") 
            or croak("you specified dir out $dir_out, but we cant copy '$abs_pdf' there, $!");
         $abs_loc=$dir_out;
         $abs_pdf = "$dir_out/$filename";
         push @TRASH, $abs_pdf;
         debug("switched to use pdf copy $abs_pdf");
      }
   }

	#debug("changing dir to abs loc '$abs_loc'");
   # WHY chdir??? I think this causes problems to sub scripts etc... ????

	#chdir($abs_loc); 
   #   or carp("pdfimages() cannot chdir into $abs_loc.") 
   #   and return [];	
   # TODO this is very freaking weird.. sometimes if you call the app pdfimages with full path, it bonks out

   
   #my @args=($WHICH_PDFIMAGES, $abs_pdf, "$abs_loc/$filename_only");
   #my @args=('pdfimages', $abs_pdf, "$abs_loc/$filename_only");
   #debug("args [bin absin namespace] [@args]");   
	#system(@args) == 0


   my $cmd = "pdfimages '$abs_pdf' '$abs_loc/$filename_only'";   

   debug('cwd is '.cwd().", $cmd");

   system($cmd) == 0   
      or croak("bad args for pdfimages [$cmd]");
	#	or croak("system [@args] bad.. $?");	 # what was the problem passing an array of args?? I think 
   # there was something funny about it...


   if( @TRASH and scalar @TRASH){
      debug("had copied, deleting @TRASH");
      unlink @TRASH;
   }

	opendir(DIR, $abs_loc) 
      or croak("can't open '$abs_loc' dir, $!");
   my @ls = readdir DIR;
   debug("ls is @ls");
   my @pagefiles = map { "$abs_loc/$_" } sort grep { /$filename_only.+\.p.m$/i } @ls;

	#my @pagefiles = map { "$abs_loc/$_" } sort grep { /$filename_only.+\.p.m$/i } readdir DIR;
	closedir DIR;

   #chdir ($cwd);
   #	chdir($cwd); # go back to same place we started ??

	unless(scalar @pagefiles){
		errstr( __PACKAGE__."::pdfimages() says, no output from pdfimages for [$abs_pdf]?\n[abs loc is: $abs_loc]");
		return [];
	}

   

   if($PDF::GetImages::FORCE_JPG){
      debug("FORCE_JPG is on, converting to jpegs..");
      @pagefiles = _convert_all_to_jpg(@pagefiles);
   }
	
	return \@pagefiles;
}

sub _convert_all_to_jpg {
   my @files = map { _convert_to_jpg($_) } @_;
   return @files;
}


sub _convert_to_jpg {
   my $_abs = shift;
   my $_out = $_abs;
   $_out=~s/\.\w{1,5}$/\.jpg/ 
      or warn("cant match ext on '$_abs'") and return;


   
   system($WHICH_CONVERT, $_abs, $_out) ==0 or  die($?);
   unlink $_abs;
   debug(" converted to $_out");
   return $_out;
}


1;

# doc moved to lib/PDF/GetImages.pod
