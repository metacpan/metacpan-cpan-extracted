package Parse::Date::Month::ID;

our $DATE = '2018-06-16'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_date_month_id $Pat);

our %month_values = (
    jan => 1,
    januari => 1,
    january => 1,

    feb => 2,
    peb => 2,
    februari => 2,
    pebruari => 2,
    february => 2,

    mar => 3,
    mrt => 3,
    maret => 3,
    march => 3,

    apr => 4,
    april => 4,

    mei => 5,
    may => 5,

    jun => 6,
    juni => 6,
    june => 6,

    jul => 7,
    juli => 7,
    july => 7,

    agu => 8,
    aug => 8,
    agt => 8,
    agustus => 8,
    august => 8,

    sep => 9,
    sept => 9,
    september => 9,

    okt => 10,
    oct => 10,
    oktober => 10,
    october => 10,

    nov => 11,
    nop => 11,
    november => 11,
    nopember => 11,

    des => 12,
    dec => 12,
    desember => 12,
    december => 12,
);

our $Pat = join("|", sort keys %month_values); $Pat = qr/(?:$Pat)/;

our %SPEC;

$SPEC{parse_date_month_id} = {
    v => 1.1,
    summary => 'Parse month name from Indonesian text',
    description => <<'_',

Returns undef when month name is unrecognized.

_
    args    => {
        text => {
            summary => 'The input text that contains month name',
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
    result_naked => 1,
};
sub parse_date_month_id {
    my %args = @_;
    my $text = $args{text};

    $text =~ s/^\s+//s;
    return undef unless length($text);

    $month_values{lc $text};
}

1;
# ABSTRACT: Parse month name from Indonesian text

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Date::Month::ID - Parse month name from Indonesian text

=head1 VERSION

This document describes version 0.001 of Parse::Date::Month::ID (from Perl distribution Parse-Date-Month-ID), released on 2018-06-16.

=head1 SYNOPSIS

 use Parse::Date::Month::ID qw(parse_date_month_id);

 my $m = parse_date_month_id(text => "sept"); # 9
 $m = parse_date_month_id(text => "mars"); # undef

=head1 DESCRIPTION

The goal of this module is to parse month names commonly found in Indonesian
text. It currently parses abbreviated and full month names in Indonesian as well
as English, since English date are also mixed in Indonesian text.

=head1 VARIABLES

None are exported by default, but they are exportable.

=head2 $Pat

A regex.

=head1 FUNCTIONS


=head2 parse_date_month_id

Usage:

 parse_date_month_id(%args) -> any

Parse month name from Indonesian text.

Returns undef when month name is unrecognized.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<text>* => I<str>

The input text that contains month name.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Date-Month-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Date-Month-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Date-Month-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

A more full-fledged Indonesian date parsing module:
L<DateTime::Format::Alami::ID>, with more dependencies.

Somewhat related: L<Parse::Number::ID>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
