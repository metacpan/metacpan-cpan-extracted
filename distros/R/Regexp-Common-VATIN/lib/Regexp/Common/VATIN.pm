package Regexp::Common::VATIN;

use strict;
use warnings FATAL => 'all';
use utf8;
use Regexp::Common qw(pattern clean no_defaults);

our $VERSION = 'v1.0'; # VERSION
# ABSTRACT: Patterns for matching EU VAT Identification Numbers

my $uk_pattern = do {
    my $multi_block  = '[0-9]{3}[ ]?[0-9]{4}[ ]?[0-9]{2}[ ]?(?:[0-9]{3})?';
    my $single_block = '(?:GD|HA)[0-9]{3}';
    "(?:$multi_block|$single_block)";
};

my %patterns = (
    AT => 'U[0-9]{8}',                          # Austria
    BE => '0[0-9]{9}',                          # Belgium
    BG => '[0-9]{9,10}',                        # Bulgaria
    CY => '[0-9]{8}[a-zA-Z]',                   # Cyprus
    CZ => '[0-9]{8,10}',                        # Czech Republic
    DE => '[0-9]{9}',                           # Germany
    DK => '(?:[0-9]{2}[ ]?){3}[0-9]{2}',        # Denmark
    EE => '[0-9]{9}',                           # Estonia
    EL => '[0-9]{9}',                           # Greece
    GR => '[0-9]{9}',                           # Greece ISO-3166
    ES => '[0-9a-zA-Z][0-9]{7}[0-9a-zA-Z]',     # Spain
    FI => '[0-9]{8}',                           # Finland
    FR => '[0-9a-zA-Z]{2}[ ]?[0-9]{9}',         # France
    GB => $uk_pattern,                          # United Kingdom
    HR => '[0-9]{11}',                          # Croatia
    HU => '[0-9]{8}',                           # Hungary
    IE => do {                                  # Ireland
        my @formats = (
            '[0-9]{7}[a-zA-Z]',
            '[0-9][A-Z][0-9]{5}[a-zA-Z]',
            '[0-9]{7}[a-zA-Z]{2}'
        );
        '(?:' . join('|', @formats) . ')';
    },
    IM => $uk_pattern,                          # Isle of Man
    IT => '[0-9]{11}',                          # Italy
    LT => '(?:[0-9]{9}|[0-9]{12})',             # Lithuania
    LU => '[0-9]{8}',                           # Luxembourg
    LV => '[0-9]{11}',                          # Latvia
    MT => '[0-9]{8}',                           # Malta
    NL => '[0-9]{9}[bB][0-9]{2}',               # The Netherlands
    PL => '[0-9]{10}',                          # Poland
    PT => '[0-9]{9}',                           # Portugal
    RO => '[0-9]{2,10}',                        # Romania
    SE => '[0-9]{12}',                          # Sweden
    SI => '[0-9]{8}',                           # Slovenia
    SK => '[0-9]{10}'                           # Slovakia
);

foreach my $alpha2 ( keys %patterns ) {
    my $prefix = $alpha2 eq 'IM'
               ? 'GB'
               : $alpha2 eq 'GR'
                   ? 'EL'
                   : $alpha2;
    pattern(
        name   => ['VATIN', $alpha2],
        create => "$prefix$patterns{$alpha2}"
    );
}

pattern(
    name   => [qw(VATIN any)],
    create => do {
        my $any = join(
            '|',
            map {
                $_ . $patterns{$_}
            } keys %patterns
        );
        "(?:$any)";
    }
);

1;
=encoding utf8

=head1 NAME

Regexp::Common::VATIN - Patterns for matching EU VAT Identification Numbers

=head1 SYNOPSIS

    use feature qw(say);
    use Regexp::Common qw(VATIN);
    say "DE123456789" =~ $RE{VATIN}{DE};  # 1
    say "DE123456789" =~ $RE{VATIN}{any}; # 1
    say "LT123ABC"    =~ $RE{VATIN}{LT};  # ""

=head1 DESCRIPTION

This module provides regular expression patterns to match any of the sanctioned
VATIN formats from the 27 nations levying a European Union value added tax. The
data found at http://ec.europa.eu/taxation_customs/vies/faq.html#item_11 is
used as the authoritative source of all patterns.

=head1 JAVASCRIPT

All patterns in this module are written to be compatible with JavaScript's
somewhat less-expressive regular expression standard. They can thus easily be
exported for use in a browser-facing web application:

    use JSON qw(encode_json);
    my $patterns = encode_json($RE{VATIN});

=head1 CAVEAT

In keeping with the standard set by the core L<Regexp::Common> modules, patterns
are neither anchored nor enclosed with word boundaries. Consider a malformed
VATIN, e.g.,

    my $vatin = "GB1234567890";

According to the sanctioned patterns from the United Kingdom, the above VATIN is
malformed (one digit too many). And yet,

    say $vatin =~ $RE{VATIN}{GB};     # 1

To test for an exact match, use start and end anchors:

    say $vatin =~ /^$RE{VATIN}{GB}$/; # ""

=head1 SEE ALSO

=over

=item L<Regexp::Common>

For documentation of the interface this set of regular expressions uses.

=item L<Business::Tax::VAT::Validation>

Checks the official EU database for registered VATINs.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013 Richard Simões. This module is released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.
