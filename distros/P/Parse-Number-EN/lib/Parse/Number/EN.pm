package Parse::Number::EN;

our $DATE = '2016-06-14'; # DATE
our $VERSION = '0.07'; # VERSION

# TODO: make it OO and customize thousand sep & decimal point

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw($Pat parse_number_en);

our %SPEC;

#our $Pat = qr/(?:
#                  [+-]?
#                  (?:
#                      (?:\d{1,3}(?:[,]\d{3})+ | \d+) (?:[.]\d*)? | # english
#                      [.]\d+
#                  )
#                  (?:[Ee][+-]?\d+)?
#              )/x;

# non /x version
our $Pat = '(?:[+-]?(?:(?:\d{1,3}(?:[,]\d{3})+|\d+)(?:[.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?)';

$SPEC{parse_number_en} = {
    v => 1.1,
    summary => 'Parse number from English text',
    description => <<'_',

This function can parse number with thousand separators (e.g. 10,000).

In the future percentage (e.g. 10.2%) and fractions (e.g. 1/3, 2 1/2) might also
be supported.

_
    args    => {
        text => {
            summary => 'The input text that contains number',
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub parse_number_en {
    my %args = @_;
    my $text = $args{text};

    return undef unless $text =~ s/^\s*($Pat)//s;
    my $n = $1;
    $n =~ s/,//g;
    $n+0;
}

1;
# ABSTRACT: Parse number from English text

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Number::EN - Parse number from English text

=head1 VERSION

This document describes version 0.07 of Parse::Number::EN (from Perl distribution Parse-Number-EN), released on 2016-06-14.

=head1 SYNOPSIS

 use Parse::Number::EN qw(parse_number_en $Pat);

 my @a = map {parse_number_en(text=>$_)}
     ("12,345.67", "-1.2e3", "x123", "1.23", "1,23");
 # @a = (12345.67, -1200, undef, 1.23, 1)

 my @b = map {/^$Pat$/ ? 1:0}
     ("12,345.67", "-1.2e3", "x123", "1,23");
 # @b = (1, 1, 0, 0)

=head1 DESCRIPTION

The goal for this module is to parse/extract numbers written in some common
notation in English text. That means, in addition to what Perl does, it also
recognizes thousand separators (and fractions, percentages in the future).

=head1 VARIABLES

None are exported by default, but they are exportable.

=head2 $Pat (REGEX)

A regex for quickly matching/extracting number from text. It's not 100% perfect
(the extracted number might not be valid), but it's simple and fast.

=head1 FUNCTIONS


=head2 parse_number_en(%args) -> any

Parse number from English text.

This function can parse number with thousand separators (e.g. 10,000).

In the future percentage (e.g. 10.2%) and fractions (e.g. 1/3, 2 1/2) might also
be supported.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<text>* => I<str>

The input text that contains number.

=back

Return value:  (any)

=head1 FAQ

=head2 How does this module differ from other number-parsing modules?

This module uses a single regex and provides the regex for you to use. Other
modules might be more accurate and/or faster. But this module is pretty fast.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Number-EN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Number-EN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Number-EN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Lingua::EN::Words2Nums>

Other Parse::Number::* modules (for other languages).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
