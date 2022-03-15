package Perinci::Examples::Table;

use 5.010001;
use strict;
use utf8;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.822'; # VERSION

our %SPEC;

$SPEC{aoaos} = {
    v => 1.1,
    summary => "Return an array of array-of-scalar (aoaos) data",
    args => {
    },
};
sub aoaos {
    my %args = @_;

    return [
        200, "OK",
        [[qw/ujang 25 laborer/],
         [qw/tini 33 nurse/],
         [qw/deden 27 actor/],],
        {
            'table.fields' => [qw/name age occupation/],
            'table.field_units' => [undef, 'year'],
        },
    ];
}

$SPEC{aohos} = {
    v => 1.1,
    summary => "Return an array of hash-of-scalar (aohos) data",
    args => {
    },
};
sub aohos {
    my %args = @_;

    return [
        200, "OK",
        [{name=>'ujang', age=>25, occupation=>'laborer', note=>'x'},
         {name=>'tini', age=>33, occupation=>'nurse', note=>'x'},
         {name=>'deden', age=>27, occupation=>'actor', note=>'x'},],
        {
            'table.fields' => [qw/name age occupation/],
            'table.field_units' => [undef, 'year'],
            'table.hide_unknown_fields' => 1,
        },
    ];
}

$SPEC{sales} = {
    v => 1.1,
    summary => "Return a table of sales data (sales of Celine Dion studio albums)",
    args => {
    },
};
sub sales {
    my %args = @_;

    my $table = [
        # french
        {year=>1981, lang=>"fr", title=>"La voix du bon Dieu", sales=>0.1e6},
        # Céline Dion chante Noël (1981), no sales data
        {year=>1982, lang=>"fr", title=>"Tellement j'ai d'amour...", sales=>0.15e6},
        {year=>1983, lang=>"fr", title=>"Les chemins de ma maison", sales=>0.1e6},
        # Chants et contes de Noël (1983), no sales data
        # Mélanie (1984), no sales data
        # C'est pour toi (1985), no sales data
        {year=>1987, lang=>"fr", title=>"Incognito", sales=>0.5e6},
        {year=>1991, lang=>"fr", title=>"Dion chante Plamondon", sales=>2e6},
        {year=>1995, lang=>"fr", title=>"D'eux", sales=>10e6},
        {year=>1998, lang=>"fr", title=>"S'il suffisait d'aimer", sales=>4e6},
        {year=>2003, lang=>"fr", title=>"1 fille & 4 types", sales=>0.876e6},
        {year=>2007, lang=>"fr", title=>"D'elles", sales=>0.3e6},
        {year=>2012, lang=>"fr", title=>"Sans attendre", sales=>1.5e6},
        {year=>2016, lang=>"fr", title=>"Encore un soir", sales=>1.5e6},

        # english
        {year=>1990, lang=>"en", title=>"Unison", sales=>4e6},
        {year=>1992, lang=>"en", title=>"Celine Dion", sales=>5e6},
        {year=>1993, lang=>"en", title=>"The color of my love", sales=>20e6},
        {year=>1996, lang=>"en", title=>"Falling into you", sales=>32e6},
        {year=>1997, lang=>"en", title=>"Let's talk about love", sales=>31e6},
        {year=>1998, lang=>"en", title=>"These are special times", tags=>"christmas", sales=>12e6},
        {year=>2002, lang=>"en", title=>"A new day has come", sales=>12e6},
        {year=>2003, lang=>"en", title=>"One heart", sales=>5e6},
        {year=>2004, lang=>"en", title=>"Miracle", sales=>2e6},
        {year=>2007, lang=>"en", title=>"Taking chances", sales=>3.1e6},
        {year=>2013, lang=>"en", title=>"Loved me back to life", sales=>1.5e6},
        {year=>2019, lang=>"en", title=>"Courage", sales=>0.332e6},
    ];

    [200, "OK", $table, {
        'table.fields' => [qw/year lang title sales/],
    }];
}

1;
# ABSTRACT: Table examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Table - Table examples

=head1 VERSION

This document describes version 0.822 of Perinci::Examples::Table (from Perl distribution Perinci-Examples), released on 2022-03-08.

=head1 DESCRIPTION

The examples in this module return table data.

=head1 FUNCTIONS


=head2 aoaos

Usage:

 aoaos() -> [$status_code, $reason, $payload, \%result_meta]

Return an array of array-of-scalar (aoaos) data.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 aohos

Usage:

 aohos() -> [$status_code, $reason, $payload, \%result_meta]

Return an array of hash-of-scalar (aohos) data.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 sales

Usage:

 sales() -> [$status_code, $reason, $payload, \%result_meta]

Return a table of sales data (sales of Celine Dion studio albums).

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
