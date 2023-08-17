package Parse::Date::Month::ID;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-16'; # DATE
our $DIST = 'Parse-Date-Month-ID'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(parse_date_month_id $Pat);

our %month_values = (
    jn => 1,
    jan => 1,
    januari => 1,
    january => 1,

    fe => 2,
    pe => 2,
    feb => 2,
    peb => 2,
    februari => 2,
    pebruari => 2,
    february => 2,

    mr => 3,
    mar => 3,
    mrt => 3,
    maret => 3,
    march => 3,

    ap => 4,
    apr => 4,
    april => 4,

    my => 5,
    me => 5,
    mei => 5,
    may => 5,

    jn => 6,
    jun => 6,
    juni => 6,
    june => 6,

    jl => 7,
    jul => 7,
    juli => 7,
    july => 7,

    au => 8,
    ag => 8,
    agu => 8,
    aug => 8,
    agt => 8,
    agustus => 8,
    august => 8,

    se => 9,
    sep => 9,
    sept => 9,
    september => 9,

    oc => 10,
    ok => 10,
    okt => 10,
    oct => 10,
    oktober => 10,
    october => 10,

    nv => 11,
    np => 11,
    nov => 11,
    nop => 11,
    november => 11,
    nopember => 11,

    de => 12,
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
    return undef unless length($text); ## no critic: Subroutines::ProhibitExplicitReturnUndef

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

This document describes version 0.002 of Parse::Date::Month::ID (from Perl distribution Parse-Date-Month-ID), released on 2023-06-16.

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

=head1 SEE ALSO

Other C<Parse::Month:Name::*> modules.

A more full-fledged Indonesian date parsing module:
L<DateTime::Format::Alami::ID>, with more dependencies.

Somewhat related: L<Parse::Number::ID>

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

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Date-Month-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
