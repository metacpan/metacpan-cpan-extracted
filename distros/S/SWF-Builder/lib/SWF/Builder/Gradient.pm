package SWF::Builder::Gradient;

use Carp;
use SWF::Builder::ExElement;

@SWF::Builder::Gradient::ISA = ('SWF::Element::Array::GRADIENT3', 'SWF::Builder::ExElement::Color::AddColor');
our $VERSION = "0.02";

sub new {
    my ($class, $is_alpha) = @_;

    bless {
	'_is_alpha' => SWF::Element::Scalar->new($is_alpha||0),
	'_gradient' => SWF::Element::Array::GRADIENT3->new,
    }, $class;
}

sub pack {
    my ($self, $stream) = @_;
    $self->{_gradient}->pack($stream);
}

sub add_color {
    my $self = shift;
    my $g = $self->{_gradient};

    while ( my ($ratio, $color) = splice(@_,0, 2) ) {
	croak "Too many gradient records (must be 1 to 8)" if @$g >= 8;
	push @$g, $g->new_element
	    ( Color => $self->_add_color($color),
	      Ratio => $ratio
	      );
    }
    $self;
}

sub matrix {
  SWF::Builder::Gradient::MATRIX->new;
}

package SWF::Builder::Gradient::MATRIX;

@SWF::Builder::Gradient::MATRIX::ISA = ('SWF::Builder::ExElement::MATRIX');

use Carp;

sub fit_to_rect {
    my $self = shift;
    my $mode = shift;
    $mode ||= 'longer';
    my @rect = @_;
    my ($x1, $y1, $x2, $y2, $sx, $sy);

    {
	if (@rect == 1) {
	    if (ref($param[0]) eq 'ARRAY') {
		@rect = @{$rect[0]};
		redo;
	    } elsif (UNIVERSAL::isa($rect[0], 'SWF::Element::RECT')) {
		($x1, $y1, $x2, $y2) = ($rect[0]->Xmin, $rect[0]->Ymin, $rect[0]->Xmax, $rect[0]->Ymax);
	    }
	} elsif ($rect[0]=~/^[XY]m/) {
	    my %rect = @rect;
	    ($x1, $y1, $x2, $y2) = @rect{qw/Xmin Ymin Xmax Ymax/};
	} else {
	    ($x1, $y1, $x2, $y2) = @rect;
	}
    }
    croak('Invalid rectangle for fit_to_rect') unless defined $x1;

    $sx = ($x2 - $x1)*20/32768;
    $sy = ($y2 - $y1)*20/32768;
    for ($mode) {
	/^fit$/ and do {
	    $self->scale($sx,$sy);
	    last;
	};
	/^width$/ and do {
	    $self->scale($sx);
	    last;
	};
	/^height$/ and do {
	    $self->scale($sy);
	    last;
	};
	/^longer$/ and do {
	    $self->scale(($sx>=$sy)?$sx:$sy);
	    last;
	};
	/^shorter$/ and do {
	    $self->scale(($sx>=$sy)?$sy:$sx);
	    last;
	};
    }
    $self->moveto(($x1+$x2)/2, ($y1+$y2)/2);  # /2*20
    $self;
}

1;
__END__

=head1 NAME

SWF::Builder::Gradient - SWF gradient object.

=head1 SYNOPSIS

    my $gr = $mc->new_gradient;
    $gr->add_color(   0 => '000000',
		     98 => '0000ff',
		    128 => 'ff0000',
		    158 => '0000ff',
		    255 => '000000',
		   );

    my $gm = $gr->matrix;
    my $shape = $mc->new_shape
        ->fillstyle($gr, 'linear', $gm)
        ->moveto( ... )
        ->lineto( ... )-> ... ;
    $gm->fit_to_rect(longer => $shape->get_bbox);

=head1 DESCRIPTION

Gradient object is a kind of fill styles of shapes. Colors are interpolated
between the control points determined by ratios.
Each gradient has 1-8 control points.


=over 4

=item $gr = $mc->new_gradient

returns a new gradient object.

=item $gr->add_color( $ratio, $color [, $ratio, $color ...])

adds control points of the gradient. 
$ratio is a position of the point. 0 maps to left/center and 255 to 
right/outer for linear/radial gradient.
$color can take a six or eight-figure
hexadecimal string, an array reference of R, G, B, and optional alpha value, 
an array reference of named parameters such as [Red => 255],
and SWF::Element::RGB/RGBA object.

=item $gm = $gr->matrix

returns a transformation matrix for the gradient.

=item $gm->fit_to_rect( $mode => @rect )

transforms the gradient matrix to fit to the rectangle.
$mode can take as follows:

=over 2

=item fit

to fit the gradient square to the rectangle. It does not keep proportion.

=item width

to fit the gradient square to the width of the rectangle,
and scales it with keeping proportion.

=item height

to fit the gradient square to the height of the rectangle,
and scales it with keeping proportion.

=item longer

to fit the gradient square to the longer side of the rectangle,
and scales it with keeping proportion.

=item shorter

to fit the gradient square to the shorter side of the rectangle,
and scales it with keeping proportion.

=back

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
