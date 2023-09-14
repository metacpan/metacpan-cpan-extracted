package Perinci::Examples::Completion;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.824'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'More completion examples',
};

$SPEC{fruits} = {
    v => 1.1,
    args => {
        fruits => {
            'x.name.is_plural' => 1,
            schema => [array => of => 'str'],
            element_completion => sub {
                my %args = @_;
                my $word = $args{word} // '';

                # complete with unmentioned fruits
                my %allfruits = (
                    apple => "One a day of this and you keep the doctor away",
                    apricot => "Another fruit that starts with the letter A",
                    banana => "A tropical fruit",
                    "butternut squash" => "Popular among babies' parents", # contain space, description contains quote
                    cherry => "Often found on cakes or drinks",
                    durian => "Lots of people hate this, but it's popular in Asia",
                );
                my $ary = $args{args}{fruits};
                my $res = [];
                for my $fruit (keys %allfruits) {
                    next unless $fruit =~ /\A\Q$word\E/i;
                    push @$res, {word=>$fruit, summary=>$allfruits{$fruit}}
                        unless grep { $fruit eq $_ } @$ary;
                }
                $res;
            },
            #req => 1,
            pos => 0,
            slurpy => 1,
        },
        category => {
            summary => 'This argument contains valid values and '.
                'their summaries in the schema',
            schema => ['str*' => {
                in => [qw/citrus tropical melon stone/],
                'x.in.summaries' => [
                    "Oranges, grapefruits, pomelos",
                    "Bananas, mangoes",
                    "Watermelons, honeydews",
                    "Apricots, nectarines, peaches",
                ],
            }],
        },
    },
    description => <<'_',

Demonstrates completion of array elements, with description for each word.

_
};
sub fruits {
    [200, "OK", {@_}];
}

$SPEC{animals} = {
    v => 1.1,
    summary => 'Specify an animal (optional) and a color (optional), '.
        'with some examples given in argument spec or schema (for completion)',
    args => {
        animal => {
            schema => ['str*', {
                'examples' => [
                    {value=>'dog', summary=>'You cannot teach this animal new tricks when it is old'},
                    {value=>'bird', summary=>'Two of this can be killed with one stone'},
                    {value=>'elephant', summary=>'It never forgets'},
                ],
            }],
            pos => 0,
        },
        color => {
            schema => ['str*'],
            examples => [
                'black',
                'blue',
                {value=>'chartreuse', summary=>'half green, half yellow'},
                {value=>'cyan', summary=>'half green, half blue'},
                'green',
                'grey',
                {value=>'magenta', summary=>'half red, half blue'},
                'red',
                'white',
                'yellow',
            ],
            pos => 1,
        },
    },
    description => <<'_',

Demonstrates Rinci argument spec `examples` property as well as Sah schema's
`examples` clause. This property is a source of valid values for the argument
and can be used for testing, documentation, or completion.

_
};
sub animals {
    [200, "OK", {@_}];
}

$SPEC{simple} = {
    v => 1.1,
    summary => 'Simple completion demo',
    args => {
        in_clause => {
            schema => ['str*', in=>[qw/one two three four fiv/]],
        },
        int_up_to_12 => {
            schema => ['int*', min=>1, max=>12],
        },
    },
};
sub simple {
    [200, "OK", {@_}];
}

1;
# ABSTRACT: More completion examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Completion - More completion examples

=head1 VERSION

This document describes version 0.824 of Perinci::Examples::Completion (from Perl distribution Perinci-Examples), released on 2023-07-09.

=for Pod::Coverage .*

=head1 FUNCTIONS


=head2 animals

Usage:

 animals(%args) -> [$status_code, $reason, $payload, \%result_meta]

Specify an animal (optional) and a color (optional), with some examples given in argument spec or schema (for completion).

Demonstrates Rinci argument spec C<examples> property as well as Sah schema's
C<examples> clause. This property is a source of valid values for the argument
and can be used for testing, documentation, or completion.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<animal> => I<str>

(No description)

=item * B<color> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 fruits

Usage:

 fruits(%args) -> [$status_code, $reason, $payload, \%result_meta]

Demonstrates completion of array elements, with description for each word.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str>

This argument contains valid values and their summaries in the schema.

=item * B<fruits> => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 simple

Usage:

 simple(%args) -> [$status_code, $reason, $payload, \%result_meta]

Simple completion demo.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in_clause> => I<str>

(No description)

=item * B<int_up_to_12> => I<int>

(No description)


=back

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
