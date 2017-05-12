package PDF::OCR2::Page;
use strict;
use vars qw($VERSION $DEBUG @TRASH $CHECK_PDF $NO_TRASH_CLEANUP);
use LEOCHARRE::Class2;
#__PACKAGE__->make_constructor_init;
__PACKAGE__->make_accessor_setget('errstr');
__PACKAGE__->make_count_for('abs_images');
__PACKAGE__->make_accessor_setget_ondisk_file( 'abs_pdf' );
use PDF::OCR2::Base;
use Carp;
use warnings;
$VERSION = sprintf "%d.%02d", q$Revision: 1.14 $ =~ /(\d+)/g;


sub new {
   my($class,$arg) = @_;
   
   my $self =
      ('HASH' eq (ref $arg)) ? $arg :
         $arg ? { abs_pdf => $arg } : {};
   
   bless $self, $class;

   if (my $arg = $self->{abs_pdf}){      
      no warnings;
      $CHECK_PDF and $PDF::OCR2::CHECK_PDF = 1; # hack
      # this checks the pdf with PDF::API2 if PDF::OCR2::CHECK_PDF or CHECK_PDF are set
      ( $self->{abs_pdf} = PDF::OCR2::Base::get_abs_pdf($arg) ) or return;
   }
   return $self;
}


sub abs_images {
   my $self = shift;
   unless( $self->{abs_images} ){
      my $abs = $self->abs_pdf;

      debug("calling PDF::GetImages for '$abs'.. ");
      require PDF::GetImages;
      my $images = PDF::GetImages::pdfimages($abs);

      defined $images or $self->errstr("PDF::GetImages::pdfimages($abs) does not return.");
      scalar @$images or $self->errstr("PDF::GetImages::pdfimages($abs) does not return values.. no images?");
      $self->{abs_images} = $images;
      $self->{abs_images} ||= [];
      debug("DEBUG is ON");
   }
   wantarray ? @{$self->{abs_images}} : $self->{abs_images};
}


sub _text_from_pdf {   
   #$_[0]->{_text_from_pdf} ||= $_[0]->_system_pdftotext( $_[0]->abs_pdf );
   $_[0]->{_text_from_pdf} ||= $_[0]->_cam_pdftotext( $_[0]->abs_pdf );

}

sub _text_from_images {
   my $self = shift;

   my $txt;
   for my $abs ( @{$self->abs_images} ){
      $txt.= $self->_text_from_image($abs);
   }
   $txt;
}

sub _length_from_images  { length $_[0]->_text_from_images   || 0 } # will attempt creation of images
sub _length_from_pdf     { length $_[0]->_text_from_pdf      || 0 } # will call pdftotext
sub _length              { length $_[0]->_text               || 0 } # will call all


sub _text_from_image {
   my($self,$abs) = @_;
   unless( $self->{_text_from_image}->{$abs} ){
      
      #   -f $abs ?       print STDERR" ===== $abs is on disk \n" : confess("No $abs on disk");

      require Image::OCR::Tesseract;
      my $txt = Image::OCR::Tesseract::get_ocr($abs);
      $self->{_text_from_image}->{$abs} = $txt;
      push @TRASH, $abs;
   }
   $self->{_text_from_image}->{$abs};
}

sub text {
   my $self = shift;

   unless($self->{text}){
      
      # text from pdf first
      my $txt = $self->_text_from_pdf;
      # check the length now ?
      
      debug( "LENGTH A, from pdf regular text ".length($txt));

      # now text from images
      $txt.= $self->_text_from_images;
      $self->{text} = $txt;

      debug( "LENGTH B, from images/ocr ".length($txt));

   }
   $self->{text};
}









# CAN BE REUSED ................. :

sub debug { $DEBUG ? print STDERR __PACKAGE__." DEBUG @_\n" : 1 }


sub _cam_pdftotext {
   my($self,$abs) = @_;
   require CAM::PDF;
   my $o = CAM::PDF->new($abs);
   my $text = $o->getPageText(1); # the whole point is this package does 1 ONE page.
   return $text;
}


# so it can be re used:
sub _system_pdftotext {
   my ($self,$abs) = @_;

   my $bin = `which pdftotext`;
   chomp $bin;
  

   my @cmd = ( $bin, '-q', $abs );

   debug(@cmd);

   my $absout = $abs;
   $absout=~s/\.pdf/.txt/i;

   local $/;
   open(OUT,'<',$absout) or $self->errstr("could not open '$absout' for reading, $!") and return;
   my $t = <OUT>;
   close OUT;
   push @TRASH, $absout;
   $t;
}

sub DESTROY { unlink @TRASH unless ( $DEBUG or $NO_TRASH_CLEANUP ) }


1;








