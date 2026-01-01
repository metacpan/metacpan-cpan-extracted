package PDF::Builder::Resource::ColorSpace::Indexed;

use base 'PDF::Builder::Resource::ColorSpace';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::ColorSpace::Indexed - Base colorspace support for indexed color models

Inherits from L<PDF::Builder::Resource::ColorSpace>

=head2 new

    PDF::Builder::Resource::ColorSpace::Indexed->new($pdf, $key, %opts)

=over

Create a new Indexed ColorSpace object.

=back

=cut

sub new {
    my ($class, $pdf, $key, %opts) = @_;

    $class = ref($class) if ref($class);
    my $self = $class->SUPER::new($pdf, $key, %opts);
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->add_elements(PDFName('Indexed'));
    $self->type('Indexed');

    return $self;
}

# unknown -- not used anywhere

sub enumColors {
    my $self = shift;

    my %col;
    my $stream = $self->{' csd'}->{' stream'};
    foreach my $n (0..255) {
        my $k = '#' . uc(unpack('H*', substr($stream, $n*3, 3)));
        $col{$k} //= $n;
    }
    return %col;
}

# unknown -- not used anywhere

sub nameColor {
    my ($self, $n) = @_;

    my %col;
    my $stream = $self->{' csd'}->{' stream'};
    my $k = '#' . uc(unpack('H*', substr($stream, $n*3, 3)));
    return $k;
}

# unknown -- not used anywhere

sub resolveNearestRGB {
    my $self = shift;
    my ($r, $g, $b) = @_; # need to be in 0-255

    my $c = 0;
    my $w = 768**2;
    my $stream = $self->{' csd'}->{' stream'};
    foreach my $n (0..255) {
        my @e = unpack('C*', substr($stream, $n*3, 3));
        my $d = ($e[0]-$r)**2 + ($e[1]-$g)**2 + ($e[2]-$b)**2;
        if ($d < $w) { 
	    $c = $n; 
	    $w = $d; 
        }
    }
    return $c;
}

1;
