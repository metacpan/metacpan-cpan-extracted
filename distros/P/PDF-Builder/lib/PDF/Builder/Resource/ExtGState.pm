package PDF::Builder::Resource::ExtGState;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::ExtGState - Graphics state dictionary support

Inherits from L<PDF::Builder::Resource>

=head1 METHODS

=head2 new

    $egs = PDF::Builder::Resource::ExtGState->new(@parameters)

=over

Returns a new extgstate object (called from $pdf->egstate()).

=back

=cut

sub new {
    my ($class, $pdf, $key) = @_;

    my $self = $class->SUPER::new($pdf,$key);

    $self->{'Type'} = PDFName('ExtGState');
    return $self;
}

=head2 strokeadjust

    $egs->strokeadjust($boolean)

=over

(No information)

=back

=cut

sub strokeadjust {
    my ($self, $var) = @_;

    $self->{'SA'} = PDFBool($var);
    return $self;
}

=head2 strokeoverprint

    $egs->strokeoverprint($boolean)

=over

(No information)

=back

=cut

sub strokeoverprint {
    my ($self, $var) = @_;

    $self->{'OP'} = PDFBool($var);
    return $self;
}

=head2 filloverprint

    $egs->filloverprint($boolean)

=over

(No information)

=back

=cut

sub filloverprint {
    my ($self, $var) = @_;

    $self->{'op'} = PDFBool($var);
    return $self;
}

=head2 overprintmode

    $egs->overprintmode($num)

=over

(No information)

=back

=cut

sub overprintmode {
    my ($self, $var) = @_;

    $self->{'OPM'} = PDFNum($var);
    return $self;
}

=head2 blackgeneration

    $egs->blackgeneration($obj)

=over

(No information)

=back

=cut

sub blackgeneration {
    my ($self, $obj) = @_;

    $self->{'BG'} = $obj;
    return $self;
}

=head2 blackgeneration2

    $egs->blackgeneration2($obj)

=over

(No information)

=back

=cut

sub blackgeneration2 {
    my ($self, $obj) = @_;

    $self->{'BG2'} = $obj;
    return $self;
}

=head2 undercolorremoval

    $egs->undercolorremoval($obj)

=over

(No information)

=back

=cut

sub undercolorremoval {
    my ($self, $obj) = @_;

    $self->{'UCR'} = $obj;
    return $self;
}

=head2 undercolorremoval2

    $egs->undercolorremoval2($obj)

=over

(No information)

=back

=cut

sub undercolorremoval2 {
    my ($self, $obj) = @_;

    $self->{'UCR2'} = $obj;
    return $self;
}

=head2 transfer

    $egs->transfer($obj)

=over

(No information)

=back

=cut

sub transfer {
    my ($self, $obj) = @_;

    $self->{'TR'} = $obj;
    return $self;
}

=head2 transfer2

    $egs->transfer2($obj)

=over

(No information)

=back

=cut

sub transfer2 {
    my ($self, $obj) = @_;

    $self->{'TR2'} = $obj;
    return $self;
}

=head2 halftone

    $egs->halftone($obj)

=over

(No information)

=back

=cut

sub halftone {
    my ($self, $obj) = @_;

    $self->{'HT'} = $obj;
    return $self;
}

=head2 halftonephase

    $egs->halftonephase($obj)

=over

(No information)

=back

=cut

# Per RT #113514, this was last present in version 1.2 of the PDF
# spec, so it can probably be removed.
sub halftonephase {
    my ($self, $obj) = @_;

    $self->{'HTP'} = $obj;
    return $self;
}

=head2 smoothness

    $egs->smoothness($num)

=over

(No information)

=back

=cut

sub smoothness {
    my ($self, $var) = @_;

    $self->{'SM'} = PDFNum($var);
    return $self;
}

=head2 font

    $egs->font($font, $size)

=over

(No information)

=back

=cut

sub font {
    my ($self, $font, $size) = @_;

    $self->{'Font'} = PDFArray(PDFName($font->{' apiname'}), PDFNum($size));
    return $self;
}

=head2 linewidth

    $egs->linewidth($size)

=over

(No information)

=back

=cut

sub linewidth {
    my ($self, $var) = @_;

    $self->{'LW'} = PDFNum($var);
    return $self;
}

=head2 linecap

    $egs->linecap($cap)

=over

(No information)

=back

=cut

sub linecap {
    my ($self, $var) = @_;

    $self->{'LC'} = PDFNum($var);
    return $self;
}

=head2 linejoin

    $egs->linejoin($join)

=over

(No information)

=back

=cut

sub linejoin {
    my ($self, $var) = @_;

    $self->{'LJ'} = PDFNum($var);
    return $self;
}

=head2 miterlimit

    $egs->miterlimit($limit)

=over

(No information)

=back

=cut

sub miterlimit {
    my ($self, $var) = @_;

    $self->{'ML'} = PDFNum($var);
    return $self;
}

# Note: miterlimit was originally named incorrectly as meterlimit, renamed

=head2 dash

    $egs->dash(@dash)

=over

(No information)

=back

=cut

sub dash {
    my ($self, @dash) = @_;

    $self->{'D'} = PDFArray(PDFArray( map { PDFNum($_); } @dash), PDFNum(0));
    return $self;
}

=head2 flatness

    $egs->flatness($flat)

=over

(No information)

=back

=cut

sub flatness {
    my ($self, $var) = @_;

    $self->{'FL'} = PDFNum($var);
    return $self;
}

=head2 renderingintent

    $egs->renderingintent($intentName)

=over

(No information)

=back

=cut

sub renderingintent {
    my ($self, $var) = @_;

    $self->{'RI'} = PDFName($var);
    return $self;
}

=head2 strokealpha

    $egs->strokealpha($alpha)

=over

The current stroking alpha constant, specifying the
constant shape or constant opacity value to be used
for stroking operations in the transparent imaging model.

=back

=cut

sub strokealpha {
    my ($self, $var) = @_;

    $self->{'CA'} = PDFNum($var);
    return $self;
}

=head2 fillalpha

    $egs->fillalpha($alpha)

=over

Same as strokealpha, but for nonstroking (fill) operations.

=back

=cut

sub fillalpha {
    my ($self, $var) = @_;

    $self->{'ca'} = PDFNum($var);
    return $self;
}

=head2 blendmode

    $egs->blendmode($blendname)

    $egs->blendmode($blendfunctionobj)

=over

The current blend mode to be used in the transparent imaging model.

=back

=cut

sub blendmode {
    my ($self, $var) = @_;

    if (ref($var)) {
        $self->{'BM'} = $var;
    } else {
        $self->{'BM'} = PDFName($var);
    }
    return $self;
}

=head2 alphaisshape

    $egs->alphaisshape($boolean)

=over

The alpha source flag (alpha is shape), specifying
whether the current soft mask and alpha constant
are to be interpreted as shape values (I<true>) or
opacity values (I<false>).

=back

=cut

sub alphaisshape {
    my ($self, $var) = @_;

    $self->{'AIS'} = PDFBool($var);
    return $self;
}

=head2 textknockout

    $egs->textknockout($boolean)

=over

The text knockout flag, which determines the behavior
of overlapping glyphs within a text object in the
transparent imaging model.

=back

=cut

sub textknockout {
    my ($self, $var) = @_;

    $self->{'TK'} = PDFBool($var);
    return $self;
}

=head2 transparency

    $egs->transparency($t)

=over

The graphics transparency, with 0 being fully opaque and 1 being fully 
transparent. This is a convenience method, setting proper values for 
C<strokealpha> and C<fillalpha>.

=back

=cut

sub transparency {
    my ($self, $t) = @_;

    $self->strokealpha(1-$t);
    $self->fillalpha(1-$t);
    return $self;
}

=head2 opacity

    $egs->opacity($op)

=over

The graphics opacity, with 1 being fully opaque and 0 being fully transparent.
This is a convenience method, setting proper values for C<strokealpha> and 
C<fillalpha>.

=back

=cut

sub opacity {
    my ($self, $var) = @_;

    $self->strokealpha($var);
    $self->fillalpha($var);
    return $self;
}

#sub outobjdeep {
#    my ($self, @opts) = @_;
#
#    foreach my $k (qw/ api apipdf /) {
#        $self->{" $k"} = undef;
#        delete($self->{" $k"});
#    }
#    return $self->SUPER::outobjdeep(@opts);
#}

1;
