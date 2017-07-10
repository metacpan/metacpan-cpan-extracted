package Printer::ESCPOS::PDF;

use strict;
use warnings;

use parent qw/ Printer::ESCPOS::Profiles::Generic /;
use PDF::API2;

=head1 NAME

Printer::ESCPOS::PDF - a hacky drop-in replacement for redirect Printer::ESCPOS output to a PDF file instead of a printer

=head1 SYNOPSIS

    use Printer::ESCPOS::PDF;

    my $printer = Printer::ESCPOS::PDF->new({ width => 815 });

    my $parser = XML::Printer::ESCPOS->new(
        printer => $printer,
    );
    $parser->parse(q#
         <escpos>
            <qr version="4" moduleSize="4">Dont panic!</qr>
        </escpos>
    #);

    $printer->save_pdf('test.pdf');

... or without XML::Printer::ESCPOS:

    Printer::ESCPOS::PDF

    my $printer = Printer::ESCPOS::PDF->new({ width => 815 });

    $printer->text('this is an example');
    $printer->lf();
    $printer->bold(1);
    $printer->text(q~this is some bold text~);
    $printer->bold(0);

    $printer->save_pdf('test.pdf');


=head1 METHODS

=head2 new

Takes an optional options hash reference for defining settings like height, width,

=cut

sub new {
    my $class = shift;
    my $options = \%{ shift() || {} };

    $options->{width} ||= 512;
    $options->{margin} ||= 10;
    $options->{width} += $options->{margin} * 2;

    $options->{pdf} = PDF::API2->new();
    $options->{page} = $options->{pdf}->page();
    $options->{page}->mediabox($options->{width}, $options->{height} ||= 1200000);
    $options->{font} = $options->{pdf}->corefont('Courier');
    $options->{font_bold} = $options->{pdf}->corefont('Courier-Bold');
    $options->{font_italic} = $options->{pdf}->corefont('Courier-Oblique');
    $options->{font_bold_italic} = $options->{pdf}->corefont('Courier-BoldOblique');
    $options->{fontsize} ||= 14;
    $options->{x} = $options->{margin};
    $options->{y} = $options->{height} - $options->{fontsize} - $options->{margin};

    return bless $options, $class;
}

=head2 save_pdf $filename

Outputs the generated PDF file to the given file.

=cut

sub save_pdf {
    my ($self, $filename) = @_;
    $self->{page}->mediabox(0, $self->{y} - $self->{margin}, $self->{width}, $self->{height});
    $self->{pdf}->saveas($filename);
}

=head2 get_pdf

Returns the generated PDF as a string.

=cut

=head1 OTHER METHODS

This module implements other methods to do the actual conversion which are 
mostly overwritten from the original Printer::ESCPOS.

=cut

sub get_pdf {
    my ($self) = @_;
    $self->{pdf}->stringify();
}

sub text {
    my ($self, $string) = @_;
    my $text = $self->{page}->text();
    $text->font($self->{bold} ? $self->{font_bold} : $self->{font}, $self->{fontsize});
    $text->translate($self->{x}, $self->{y});
    $text->text($string);
    $self->{x} += int(length($string) * 10);
}

sub lf {
    my $self = shift;
    $self->{x} = $self->{margin};
    $self->{y} -= $self->{fontsize};
}

sub bold {
    my ($self, $value) = @_;
    $self->{bold} = $value;
}

sub underline {
    my ($self, $value) = @_;
    $self->{underline} = $value;
}

sub invert {
    my ($self, $value) = @_;
    $self->{invert} = $value;
}

sub doubleStrike {
    my ($self, $value) = @_;
    $self->{doubleStrike} = $value;
}

sub justify {
    my ($self, $value) = @_;
    $self->{justify} = $value;
}

sub upsideDown {
    my ($self, $value) = @_;
    $self->{upsideDown} = $value;
}

sub image {
    my ($self, $gd) = @_;
    my $gfx = $self->{page}->gfx();
    my ($width, $height) = $gd->getBounds();
    $gfx->image(
        $self->{pdf}->image_gd($gd),
        $self->{x},
        $self->{y} - $height,
        $width,
        $height,
    );

    $self->{x} = $self->{margin};
    $self->{y} -= $height;
}

sub tab {
    shift->{x} += 4 * 10;
}

sub font {}

sub color {}

sub fontHeight {}

sub fontWidth {}

sub charSpacing {}

sub lineSpacing {}

sub selectDefaultLineSpacing {}

sub printPosition {}

sub leftMargin {
    my ($self, $value) = @_;
    $self->{leftMargin} = $value;
}

sub rot90 {}

sub printNVImage {}

sub printImage {}

sub cutPaper {}

sub drawerKickPulse {}

sub print {}

=head1 BUGS

This is a quite hacky implementation that I need to output the content of 
a print in a web browser. Many values are hard-coded and should be configurable.

=head1 SEE ALSO

=over 4

=item *

L<XML::Printer::ESCPOS>

=item *

L<Printer::ESCPOS>

=back

=head1 AUTHOR

  Dominic Sonntag <dominic@s5g.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by E. Xavier Ample.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

1;