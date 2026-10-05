package String::Increment::Parts;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-07-22'; # DATE
our $DIST = 'String-Increment-Parts'; # DIST
our $VERSION = '0.002'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(
                       increment_string_parts
               );

our %SPEC;

$SPEC{increment_string_parts} = {
    v => 1.1,
    summary => 'Increment string parts (numbers or letter sequences)',
    description => <<'MARKDOWN',

This routine takes a string and splits it into a list of (uppercase letter
sequences, lowercase letter sequences, 0-9 sequences [nonnegative integers], or
anything in between). After that you can tell it to increment the letter/number
sequences.

This routine is handy when you want to generate a serial sequence of codes.

Note that for incrementing letters, Perl's auto-increment or auto-decrement is
used. If you instruct the function to increment by 100 (set `inc` argument to
100), it will do so 100 times.

MARKDOWN
    args => {
        string => {
            schema => 'str*',
            req => 1,
            pos => 0,
            tags => ['category:input'],
            cmdline_aliases => {s=>{}},
        },
        inc => {
            schema => 'int*',
            default => 1,
            cmdline_aliases => {i=>{}},
        },
        indexes => {
            schema => ['array*', of=>'int*'],
            default => [-1],
        },
        all_indexes => {
            schema => 'bool*',
        },
        filename => {
            summary => 'Treat string as filename and do not include the extension as parts',
            schema => 'bool*',
            cmdline_aliases => {f=>{}},
        },
        n => {
            summary => 'How many times to repeat the increment and return the result',
            schema => 'posint*',
            default => 1,
        },
    },
    args_rels => {
        'choose_one&' => [
            [qw/indexes all_indexes/],
        ],
    },
    result_naked => 1,
};
sub increment_string_parts {
    my %args = @_;

    my $string = $args{string};
    my $n = $args{n} // 1;
    my $inc = $args{inc} // 1;

    my $suffix;
    if ($args{filename}) {
        $string =~ s/(\.\w+)\z//;
        $suffix = $1 // '';
    } else {
        $suffix = '';
    }

    my @parts;
    my @parts_types;
    my @parts_indexes;
  SPLIT: {
        while ($string =~ /(?:([A-Z]+)|([a-z]+)|([0-9]+)|([^A-Za-z0-9]+))/g) {
            if (defined($1) || defined($2)) {
                push @parts, $1 // $2;
                push @parts_types, 'l'; # letter sequences
                push @parts_indexes, $#parts;
            } elsif (defined $3) {
                push @parts, $3;
                push @parts_types, 'n'; # number sequences
                push @parts_indexes, $#parts;
            } else {
                push @parts, $4;
                push @parts_types, 'o'; # other
            }
        }
    } # SPLIT

    my @results;
  INCREMENT: {
        for my $i (1 .. $n) {

            my @indexes;
            if ($args{all_indexes}) {
                @indexes = 0 .. $#parts_indexes;
            } elsif ($args{indexes}) {
                @indexes = @{ $args{indexes} };
            } else {
                @indexes = -1;
            }

            my %incremented_indexes;
          INDEX:
            for my $index (@indexes) {
                if ($index < 0) { $index = @parts_indexes + $index }
                unless ($index >= 0 && $index < @parts_indexes) {
                    warn "Index of parts $index is out of bounds, not incrementing any part";
                    next INDEX;
                }
                # avoid duplicate incrementing
                next INDEX if $incremented_indexes{$index + 0};

              INCREMENT_PART: {
                    my $part = $parts      [ $parts_indexes[$index] ];
                    my $type = $parts_types[ $parts_indexes[$index] ];

                    if ($type eq 'l') {
                        if ($inc > 0) {
                            for my $j (1 .. $inc) { $part++ }
                        } else {
                            for my $j (1 .. $inc) { $part-- }
                        }
                    } elsif ($type eq 'n') {
                        my $width = length($part);
                        $part += $inc;
                        $part = sprintf("%0${width}d", $part);
                    } else {
                        # shouldn't happen
                    }

                    $parts[ $parts_indexes[$index] ] = $part;
                } # INCREMENT_PART
            } # INDEX

            my $result = join(
                "",
                @parts,
                $suffix,
            );
            push @results, $result;
        }
    }

    @results == 1 ? $results[0] : \@results;
}

1;
# ABSTRACT: Increment string parts (numbers or letter sequences)

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Increment::Parts - Increment string parts (numbers or letter sequences)

=head1 VERSION

This document describes version 0.002 of String::Increment::Parts (from Perl distribution String-Increment-Parts), released on 2026-07-22.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 increment_string_parts

Usage:

 increment_string_parts(%args) -> any

Increment string parts (numbers or letter sequences).

This routine takes a string and splits it into a list of (uppercase letter
sequences, lowercase letter sequences, 0-9 sequences [nonnegative integers], or
anything in between). After that you can tell it to increment the letter/number
sequences.

This routine is handy when you want to generate a serial sequence of codes.

Note that for incrementing letters, Perl's auto-increment or auto-decrement is
used. If you instruct the function to increment by 100 (set C<inc> argument to
100), it will do so 100 times.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_indexes> => I<bool>

(No description)

=item * B<filename> => I<bool>

Treat string as filename and do not include the extension as parts.

=item * B<inc> => I<int> (default: 1)

(No description)

=item * B<indexes> => I<array[int]> (default: [-1])

(No description)

=item * B<n> => I<posint> (default: 1)

How many times to repeat the increment and return the result.

=item * B<string>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Increment-Parts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Increment-Parts>.

=head1 SEE ALSO

L<String::Incremental>.

Perl's auto-increment and auto-decrement documentation in L<perlop>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Increment-Parts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
