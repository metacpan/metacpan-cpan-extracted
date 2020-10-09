package Spreadsheet::ParseODS::Styles;
use 5.010; # for //
use Moo 2;
use Carp qw(croak);
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use PerlX::Maybe;

our $VERSION = '0.32';

=head1 NAME

Spreadsheet::ParseODS::Styles - styles / formatting of cells in a workbook

=cut

has 'styles' => (
    is => 'lazy',
    default => sub { {} },
);

sub part_to_format( $self, $part ) {
    my $t = $part->tag;
    my $res;
    if( $t eq 'number:seconds' ) {
        my $style = $part->att('number:style');
        if( $style and $style eq 'long') {
            $res = 'SS';
        } else {
            $res = 'S';
        };
        #warn $part->toString;
    } elsif( $t eq 'number:minutes' ) {
        my $style = $part->att('number:style');
        if( $style and $style eq 'long') {
            $res = 'MM';
        } else {
            $res = 'M';
        };
        #warn $part->toString;
    } elsif( $t eq 'number:hours' ) {
        my $style = $part->att('number:style');
        if( $style and $style eq 'long') {
            $res = 'HH';
        } else {
            $res = 'H';
        };
        #warn $part->toString;
    } elsif( $t eq 'number:am-pm' ) {
        $res = 'am';
        #warn $part->toString;
    } elsif( $t eq 'number:day' ) {
        my $style = $part->att('number:style');
        if( $style and $style eq 'long') {
            $res = 'dd';
        } else {
            $res = 'd';
        };
    } elsif( $t eq 'number:day-of-week' ) {
        $res = 'ddd';
        #warn $part->toString;
    } elsif( $t eq 'number:week-of-year' ) {
        $res = 'ww';
        #warn $part->toString;
    } elsif( $t eq 'number:month' ) {
        my $style = $part->att('number:style');
        my $month_name = $part->att('number:textual');
        if( $month_name and $month_name eq 'true') {
            $res = 'mmm';
        } elsif( $style and $style eq 'long') {
            $res = 'mm';
        } else {
            $res = 'm';
        };
        #warn $part->toString;
    } elsif( $t eq 'number:year' ) {
        my $style = $part->att('number:style');
        if( $style and $style eq 'long') {
            $res = 'yyyy';
        } else {
            $res = 'yy';
        };
        #warn $part->toString;
    } elsif( $t eq 'number:number' ) {
        $res = '#' x ($part->att('number:min-integer-digits') || 1);

        if( defined( my $dec = $part->att('number:decimal-places'))) {
            $res .= '.' . ('0' x $dec);
        };
        #warn $part->toString;
    } elsif( $t eq 'number:scientific-number' ) {
        $res = '#' x $part->att('number:min-integer-digits');

        if( defined( my $dec = $part->att('number:decimal-places'))) {
            $res .= '.' . ('0' x $dec);
        };
        $res .= 'E+';
        if( defined( my $dec = $part->att('number:exponent-digits'))) {
            $res .= '.' . ('#' x $dec);
        };

        #warn $part->toString;
    } elsif( $t eq 'number:text' ) {
        $res = $part->text;
    } elsif( $t eq 'number:text-content' or $t eq 'number:currency-symbol' ) {
        $res = $part->text;
    } elsif( $t eq 'number:fraction' ) {
        $res = '#' x $part->att('number:min-integer-digits');

        if( defined( my $num = $part->att('number:min-numerator-digits'))) {
            $res .= ' ' . ('#' x $num);

            my $den = $part->att('number:min-denominator-digits');
            $res .= '/' . ('#' x $den);
        };
    } elsif( $t eq 'loext:text' ) {
        $res = $part->text;
    } elsif( $t eq 'style:text-properties' or $t eq 'style:properties' ) {
        # ignored
    } elsif( $t eq 'loext:fill-character' ) {
        # ignored
    } elsif( $t eq 'number:fill-character' ) {
        # ignored
    } elsif( $t eq 'style:map' ) {
        # ignored
    } elsif( $t eq '#PCDATA' ) {
        # ignored
    } else {
        warn "Unknown tag name '$t'";
        warn $part->toString;
    };
    return $res
}

sub to_format( $self, $style ) {
    return join "", map { my $res = $self->part_to_format( $_ ) // '' } $style->children
}

sub read_from_twig( $self, $elt ) {
    my $styles = $self->styles;

    for my $style ($elt->findnodes(join " | ",
        '//style:default-style',
        '//number:date-style',
        '//number:number-style',
        '//number:text-style',
        '//number:time-style',
        '//number:currency-style',
    )) {
        my $name =  $style->att('style:data-style-name')
                 || $style->att('style:name');

        # Currently we simply ignore the default style...
        next unless defined $name;

        # ignore language and country
        # This is not ideal, but oh well
        my $format = $self->to_format( $style );
        my ($font) = map { $_->att('style:font-name') } $style->findnodes('style:text-properties');

#warn "Defined '$name' as '$format'";
#warn $style->toString unless $format;
        $styles->{ $name } = {
            format    => $format,
            font_face => $font,
        };
    };

}

1;
