package PDF::OCR2::Base::Image; # this should be Image::OCR::Tesseract:OO
use strict;
use LEOCHARRE::Class2;
__PACKAGE__->make_accessor_get(qw/abs_path/);
use Image::OCR::Tesseract;
use Carp;
sub new {
   my ($class,$arg) =@_;
   
   my $self = {};
   require Cwd;      
   my $abs = Cwd::abs_path($arg)
      or Carp::cluck("Can't get abs path to '$arg'")
      and return;

   -f $abs 
      or Carp::cluck("Not on disk: '$abs'")
      and return;
      
   $self->{abs_path} = $abs;

   bless $self, $class;
   return $self;
}

sub text {
   my $self = shift;
   
   unless( defined $self->{text}){  
      my $abs = $self->abs_path;
      $self->{text} ||= Image::OCR::Tesseract::get_ocr($abs);
      $self->{text} 
         or warn("No text in '$abs'?");      
   }
   $self->{text};
}

sub text_length { length( $_[0]->text ) || 0 }




1;








1;

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

Do not use this api.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


