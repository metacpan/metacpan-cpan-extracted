package PDF::Builder::Resource::XObject::Form::BarCode;

use base 'PDF::Builder::Resource::XObject::Form::Hybrid';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::XObject::Form::BarCode - Base class for one-dimensional barcodes

Inherits from L<PDF::Builder::Resource::XObject::Form::Hybrid>

=head1 METHODS

=head2 new

    $barcode = PDF::Builder::Resource::XObject::Form::BarCode->new($pdf, %options)

=over

Creates a barcode form resource.

=back

=cut

sub new {
    my ($class, $pdf, %options) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $options{'-font'} && !defined $options{'font'}) { $options{'font'} = delete($options{'-font'}); }
    if (defined $options{'-umzn'} && !defined $options{'umzn'}) { $options{'umzn'} = delete($options{'-umzn'}); }
    if (defined $options{'-lmzn'} && !defined $options{'lmzn'}) { $options{'lmzn'} = delete($options{'-lmzn'}); }
    if (defined $options{'-zone'} && !defined $options{'zone'}) { $options{'zone'} = delete($options{'-zone'}); }
    if (defined $options{'-quzn'} && !defined $options{'quzn'}) { $options{'quzn'} = delete($options{'-quzn'}); }
    if (defined $options{'-ofwt'} && !defined $options{'ofwt'}) { $options{'ofwt'} = delete($options{'-ofwt'}); }
    if (defined $options{'-fnsz'} && !defined $options{'fnsz'}) { $options{'fnsz'} = delete($options{'-fnsz'}); }
    if (defined $options{'-spcr'} && !defined $options{'spcr'}) { $options{'spcr'} = delete($options{'-spcr'}); }
    if (defined $options{'-mils'} && !defined $options{'mils'}) { $options{'mils'} = delete($options{'-mils'}); }
    if (defined $options{'-color'} && !defined $options{'color'}) { $options{'color'} = delete($options{'-color'}); }

    my $self = $class->SUPER::new($pdf);

    $self->{' bfont'} = $options{'font'};

    $self->{' umzn'} = $options{'umzn'} || 0;    # (u)pper (m)ending (z)o(n)e
    $self->{' lmzn'} = $options{'lmzn'} || 0;    # (l)ower (m)ending (z)o(n)e
    $self->{' zone'} = $options{'zone'} || 0;    # barcode height
    $self->{' quzn'} = $options{'quzn'} || 0;    # (qu)iet (z)o(n)e
    $self->{' ofwt'} = $options{'ofwt'} || 0.01; # (o)ver(f)low (w)id(t)h
    $self->{' fnsz'} = $options{'fnsz'};         # (f)o(n)t(s)i(z)e
    $self->{' spcr'} = $options{'spcr'} || '';   # (sp)a(c)e(r) between chars in label
    $self->{' mils'} = $options{'mils'} || 1000/72; # single barcode unit width. 1 mil = 1/1000 of one inch. 1000/72 - for backward compatibility
    $self->{' color'} = $options{'color'} || 'black'; # barcode color

    return $self;
}

my %bar_widths = (
     0 => 0,
     1 => 1, 'a' => 1, 'A' => 1,
     2 => 2, 'b' => 2, 'B' => 2,
     3 => 3, 'c' => 3, 'C' => 3,
     4 => 4, 'd' => 4, 'D' => 4,
     5 => 5, 'e' => 5, 'E' => 5,
     6 => 6, 'f' => 6, 'F' => 6,
     7 => 7, 'g' => 7, 'G' => 7,
     8 => 8, 'h' => 8, 'H' => 8,
     9 => 9, 'i' => 9, 'I' => 9,
);

sub encode {
    my ($self, $string) = @_;

    my @bars = map { [ $self->encode_string($_), $_ ] } split(//, $string);
    return @bars;
}

sub encode_string {
    my ($self, $string) = @_;

    my $bar;
    foreach my $character (split(//, $string)) {
        $bar .= $self->encode_char($character);
    }
    return $bar;
}

sub drawbar {
    my $self = shift();
    my @sets = @{shift()};
    my $caption = shift();

    $self->fillcolor($self->{' color'});
    $self->strokecolor($self->{' color'});
    $self->linedash();

    my $x = $self->{' quzn'};
    my $is_space_next = 0;
    my $wdt_factor = $self->{' mils'} / 1000 * 72;
    foreach my $set (@sets) {
        my ($code, $label);
        if (ref($set)) {
            ($code, $label) = @{$set};
        } else {
            $code = $set;
            $label = undef;
        }

        my $code_width = 0;
        my ($font_size, $y_label);
        foreach my $bar (split(//, $code)) {
            my $bar_width = $bar_widths{$bar} * $wdt_factor;

            my ($y0, $y1);
            if      ($bar =~ /[0-9]/) {
                $y0 = $self->{' quzn'} + $self->{' lmzn'};
                $y1 = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'};
                $y_label   = $self->{' quzn'};
                if ($self->{' fnsz'} and $self->{' lmzn'} < $self->{' fnsz'}) {
                    $y_label -= $self->{' fnsz'} * 0.8 - $self->{' lmzn'};
                }
                $font_size = $self->{' fnsz'} || $self->{' lmzn'};
            } elsif ($bar =~ /[a-z]/) {
                $y0 = $self->{' quzn'};
                $y1 = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'};
                $y_label   = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'} + 2;
                $font_size = $self->{' fnsz'} || $self->{' umzn'};
            } elsif ($bar =~ /[A-Z]/) {
                $y0 = $self->{' quzn'};
                $y1 = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'};
                $font_size = $self->{' fnsz'} || $self->{' umzn'};
                $y_label   = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'} - $font_size;
            } else {
                $y0 = $self->{' quzn'} + $self->{' lmzn'};
                $y1 = $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'};
                $y_label   = $self->{' quzn'};
                $font_size = $self->{' fnsz'} || $self->{' lmzn'};
            }

            unless ($is_space_next or $bar eq '0') {
                $self->linewidth($bar_width - $self->{' ofwt'});
                $self->move($x + $code_width + $bar_width / 2, $y0);
                $self->line($x + $code_width + $bar_width / 2, $y1);
                $self->stroke();
            }
            $is_space_next = not $is_space_next;

            $code_width += $bar_width;
        }

        if (defined($label) and $self->{' lmzn'}) {
            $label = join($self->{' spcr'}, split(//, $label));
            $self->textstart();
            $self->translate($x + ($code_width / 2), $y_label);
            $self->font($self->{' bfont'}, $font_size);
            $self->text_center($label);
            $self->textend();
        }

        $x += $code_width;
    }

    $x += $self->{' quzn'};

    if (defined $caption) {
        my $font_size = $self->{' fnsz'} || $self->{' lmzn'};
        my $y_caption = $self->{' quzn'} - $font_size;
        $self->textstart();
        $self->translate($x / 2, $y_caption);
        $self->font($self->{' bfont'}, $font_size);
        $self->text_center($caption);
        $self->textend();
    }

    $self->{' w'} = $x;
    $self->{' h'} = 2 * $self->{' quzn'} + $self->{' lmzn'} + $self->{' zone'} + $self->{' umzn'};
    $self->bbox(0, 0, $self->{' w'}, $self->{' h'});
    return;
}

=head2 width

    $width = $barcode->width()

=over

Returns the width of the bar code.

=back

=cut

sub width {
    my $self = shift;

    return $self->{' w'};
}

=head2 height

    $height = $barcode->height()

=over

Returns the height of the bar code.

=back

=cut


sub height {
    my $self = shift;

    return $self->{' h'};
}

1;
