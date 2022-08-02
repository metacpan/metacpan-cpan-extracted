package Term::Graille::Chart;
use strict; use warnings;
use utf8;
use Term::Graille  qw/colour paint printAt clearScreen border blockBlit block2braille pixelAt/;
use open ":std", ":encoding(UTF-8)";

our $VERSION="0.071";


sub new{
    my ($class, %params) = @_; 
    $self->{canvas}=new Term::Graille->new(
          width  => $params{width}//120,
          height => $params{height}//60,
          top    => $params{top}//4,
          left   => $params{lrft}//10,
          borderStyle => "double",
          );
    bless $self,$class;
    return $self;
}

sub draw{
	my $self=shift;
	$self->{canvas}->draw();
}
