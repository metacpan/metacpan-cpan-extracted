package PDF::Builder::Resource::ColorSpace::Indexed::WebColor;

use base 'PDF::Builder::Resource::ColorSpace::Indexed';

use strict;
use warnings;
#no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.022'; # VERSION
my $LAST_UPDATE = '3.021'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::ColorSpace::Indexed::WebColor - colorspace support for "Web Safe" Device RGB colors. Inherits from L<PDF::Builder::Resource::ColorSpace::Indexed>

=cut

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

sub new {
    my ($class, $pdf) = @_;

    $class = ref $class if ref $class;
    my $self = $class->SUPER::new($pdf, pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};
    my $csd = PDFDict();
    $pdf->new_obj($csd);
    $csd->{'Filter'} = PDFArray(PDFName('ASCIIHexDecode'));
    $csd->{'WhitePoint'} = PDFArray(map {PDFNum($_)} (0.95049, 1, 1.08897));
    $csd->{'BlackPoint'} = PDFArray(map {PDFNum($_)} (0, 0, 0));
    $csd->{'Gamma'} = PDFArray(map {PDFNum($_)} (2.22218, 2.22218, 2.22218));
    $csd->{' stream'}='';

    foreach my $r (0,0x33,0x66,0x99,0xCC,0xFF) {
        foreach my $g (0,0x33,0x66,0x99,0xCC,0xFF) {
            foreach my $b (0,0x33,0x66,0x99,0xCC,0xFF) {
                $csd->{' stream'} .= pack('CCC', $r,$g,$b);
            }
        }
    } # 0-215

    foreach my $r (0,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF) {
        $csd->{' stream'} .= pack('CCC', $r,$r,$r);
    } # 216-231
    foreach my $r (0,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xAA,0xBB,0xCC,0xDD,0xEE,0xFF) {
        $csd->{' stream'} .= pack('CCC', map { $_*255 } namecolor('!'.sprintf('%02X', $r).'FFFF'));
    } # 232-247
    foreach my $r (0,0x22,0x44,0x66,0x88,0xAA,0xCC,0xEE) {
        $csd->{' stream'} .= pack('CCC', map { $_*255 } namecolor('!'.sprintf('%02X', $r).'FF99'));
    } # 232-247

    $csd->{' stream'} .= "\x00" x 768;
    $csd->{' stream'} = substr($csd->{' stream'}, 0, 768);

    $self->add_elements(PDFName('DeviceRGB'), PDFNum(255), $csd);
    $self->{' csd'} = $csd;

    return $self;
}

1;
