package Parse::Date::Month::EN;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-16'; # DATE
our $DIST = 'Parse-Date-Month-EN'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(parse_date_month_en $Pat);

our %month_values = (
    jn => 1,
    jan => 1,
    january => 1,

    fe => 2,
    feb => 2,
    february => 2,

    mr => 3,
    mar => 3,
    march => 3,

    ap => 4,
    apr => 4,
    april => 4,

    my => 5,
    may => 5,

    jn => 6,
    jun => 6,
    june => 6,

    jl => 7,
    jul => 7,
    july => 7,

    au => 8,
    agt => 8,
    aug => 8,
    august => 8,

    se => 9,
    sep => 9,
    sept => 9,
    september => 9,

    oc => 10,
    oct => 10,
    october => 10,

    nv => 11,
    nov => 11,
    nop => 11,
    november => 11,

    de => 12,
    dec => 12,
    december => 12,
);

our $Pat = join("|", sort keys %month_values); $Pat = qr/(?:$Pat)/;

our %SPEC;

$SPEC{parse_date_month_en} = {
    v => 1.1,
    summary => 'Parse month name from English text',
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
sub parse_date_month_en {
    my %args = @_;
    my $text = $args{text};

    $text =~ s/^\s+//s;
    return undef unless length($text); ## no critic: Subroutines::ProhibitExplicitReturnUndef

    $month_values{lc $text};
}

1;
# ABSTRACT: Parse month name from English text

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Date::Month::EN - Parse month name from English text

=head1 VERSION

This document describes version 0.001 of Parse::Date::Month::EN (from Perl distribution Parse-Date-Month-EN), released on 2023-06-16.

=head1 SYNOPSIS

 use Parse::Date::Month::EN qw(parse_date_month_en);

 my $m = parse_date_month_en(text => "sept"); # 9
 $m = parse_date_month_en(text => "mars"); # undef

=head1 DESCRIPTION

The goal of this module is to parse month names commonly found in English text.
It currently parses abbreviated and full month names in English.

=head1 VARIABLES

None are exported by default, but they are exportable.

=head2 $Pat

A regex.

=head1 FUNCTIONS


=head2 parse_date_month_en

Usage:

 parse_date_month_en(%args) -> any

Parse month name from English text.

Returns undef when month name is unrecognized.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<text>* => I<str>

The input text that contains month name.


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Date-Month-EN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Date-Month-EN>.

=head1 SEE ALSO

Other C<Parse::Month::Name::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Date-Month-EN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
