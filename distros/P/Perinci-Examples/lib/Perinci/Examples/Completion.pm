package Perinci::Examples::Completion;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';

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
                for (keys %allfruits) {
                    next unless /\A\Q$word\E/i;
                    push @$res, {word=>$_, summary=>$allfruits{$_}}
                        unless $_ ~~ @$ary;
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

1;
# ABSTRACT: More completion examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Completion - More completion examples

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::Completion (from Perl distribution Perinci-Examples), released on 2019-06-29.

=for Pod::Coverage .*

=head1 FUNCTIONS


=head2 fruits

Usage:

 fruits(%args) -> [status, msg, payload, meta]

Demonstrates completion of array elements, with description for each word.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str>

This argument contains valid values and their summaries in the schema.

=item * B<fruits> => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
