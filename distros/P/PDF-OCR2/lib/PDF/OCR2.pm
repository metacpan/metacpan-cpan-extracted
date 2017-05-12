package PDF::OCR2;
use strict;
use PDF::OCR2::Page;
use PDF::OCR2::Base;
use LEOCHARRE::Class2;
use Carp;
use vars qw($VERSION $DEBUG @TRASH $CHECK_PDF $NO_TRASH_CLEANUP $REPAIR_XREF);
__PACKAGE__->make_accessor_setget( 'abs_path', );
#__PACKAGE__->make_accessor_setget_unique_array(')
__PACKAGE__->make_count_for( '_abs_bursts' );
$VERSION = sprintf "%d.%02d", q$Revision: 1.21 $ =~ /(\d+)/g;

sub debug { $DEBUG or return 1; print STDERR  __PACKAGE__.": @_\n"; 1 }
*page = \&_page;
*pages_count = \&_abs_bursts_count;

sub new {
   my($class,$arg) = @_;
   if( $arg and ref $arg ){ croak("argument to constructor must be path to pdf"); }
   $arg or croak('missing arg to constructor');
   
   my $self = {};
   bless $self, $class;

   # this checks the pdf with PDF::API2 if PDF::OCR2::CHECK_PDF is set
   ( $self->{abs_path} = PDF::OCR2::Base::get_abs_pdf($arg) ) or return;

   return $self;
}







sub _abs_bursts {
   my $self = shift;

   unless( $self->{_abs_bursts} ){
      my $abs = $self->abs_path or warn("Cant burst, no abs path") and return;
      print STDERR __PACKAGE__."::_abs_bursts() bursting '$abs'.. " if $DEBUG;

      require PDF::Burst;
      my @abs = PDF::Burst::pdf_burst($abs) or warn('error'); #carp($PDF::Burst::errstr);
      $self->{_abs_bursts} = [@abs]; # even if none returned, now contains aref
      push @TRASH, @abs; 

      print STDERR "Done. Got: @abs\n" if $DEBUG;
   }
   
   wantarray and return @{$self->{_abs_bursts}};
   return $self->{_abs_bursts};
}

sub _page { # return page object
   my($self,$pagenum) = @_;
   
   $pagenum=~/\D/ and croak("arg must be page number");
   
   unless( $self->{page}->{$pagenum} ){
      debug("instancing page object page $pagenum");
      my $abs = $self->_abs_bursts->[($pagenum - 1 )] 
         or croak("No such page num: $pagenum");
      debug($abs);
      my $o = 
         PDF::OCR2::Page->new({ abs_pdf => $abs }) 
         or die("Could not instance PDF::OCR2::Page for $abs");
      $self->{page}->{$pagenum} = $o;
   }
   $self->{page}->{$pagenum};
}



sub text {
   my $self = shift;

   my @texts;

   debug( " bursts count: ". $self->_abs_bursts_count);

   for my $pagenum ( 1 .. $self->_abs_bursts_count ){
      my $p = $self->_page($pagenum);
      push @texts, $p->text;
   }

   wantarray ? @texts : join( "\f", @texts);
}

sub text_length { length( scalar $_[0]->text ) }


sub DESTROY { unlink @TRASH unless ( $DEBUG or $NO_TRASH_CLEANUP ) }


1;



