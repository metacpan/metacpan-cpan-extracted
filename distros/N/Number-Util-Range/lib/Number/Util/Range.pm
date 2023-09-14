package Number::Util::Range;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-08'; # DATE
our $DIST = 'Number-Util-Range'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(convert_number_sequence_to_range);
our %SPEC;

$SPEC{'convert_number_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in number arrays & convert to range '.
    '(e.g. 100,2,3,4,5,101 -> 100,"2..5",101)',
    description => <<'MARKDOWN',

This routine accepts an array, finds sequences of numbers in it (e.g. 1, 2, 3),
and converts each sequence into a range ("1..3"). So basically it "compresses" the
sequence (many elements) into a single element.

MARKDOWN
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        min_range_len => {
            schema => ['posint*', min=>2],
            default => 4,
            description => <<'MARKDOWN',

Minimum number of items in a sequence to convert to a range. Sequence that has
less than this number of items will not be converted.

MARKDOWN
        },
        max_range_len => {
            schema => ['posint*',min=>2],
            description => <<'MARKDOWN',

Maximum number of items in a sequence to convert to a range. Sequence that has
more than this number of items might be split into two or more ranges.

MARKDOWN
        },
        separator => {
            schema => 'str*',
            default => '..',
        },
        ignore_duplicates => {
            schema => 'true*',
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'basic, non-numbers ignored',
            args => {
                array => [100, 2, 3, 4, 5, 101, 'foo'],
            },
            result => [100, "2..5", 101, 'foo'],
        },
        {
            summary => 'option: separator',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                separator => '-',
            },
            result => [100, "2-5", 101],
        },
        {
            summary => 'multiple ranges, negative number',
            args => {
                array => [100, 2, 3, 4, 5, 6, 101, 102, -5, -4, -3, -2, 103],
            },
            result => [100, "2..6", 101, 102, "-5..-2", 103],
        },
        {
            summary => 'option: min_range_len (1)',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                min_range_len => 5,
            },
            result => [100, 2, 3, 4, 5, 101],
        },
        {
            summary => 'option: min_range_len (2)',
            args => {
                array => [100, 2, 3, 4, 101, 'foo'],
                min_range_len => 3,
            },
            result => [100, "2..4", 101, 'foo'],
        },
        {
            summary => 'option: ignore_duplicates',
            args => {
                array => [1, 2, 3, 4, 2, 9, 9, 9],
                ignore_duplicates => 1,
            },
            result => ["1..4", 9],
        },
        {
            summary => 'option: max_range_len (1)',
            args => {
                array => [98, 100..110, 5, 101],
                max_range_len => 4,
            },
            result => [98, "100..103","104..107", 108, 109, 110, 5, 101],
        },
    ],
};
sub convert_number_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $min_range_len = $args{min_range_len}
        // $args{threshold} # old name, DEPRECATED
        // 4;
    my $max_range_len = $args{max_range_len};
    my $separator = $args{separator} // '..';
    my $ignore_duplicates = $args{ignore_duplicates};

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $min_range_len ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    my %seen;
    for my $i (0..$#{$array}) {
        my $el = $array->[$i];

        next if $ignore_duplicates && $seen{$el}++;

        unless ($el =~ /\A-?[0-9]+\z/) { # not an integer
            $code_empty_buffer->();
            push @res, $el;
            next;
        }
        if (@buf) {
            if ($el != $buf[-1]+1) { # breaks current sequence
                $code_empty_buffer->();
            }
            if ($max_range_len && @buf >= $max_range_len) {
                $code_empty_buffer->();
            }
        }
        push @buf, $el;
    }
    $code_empty_buffer->();

    \@res;
}

1;

# ABSTRACT: Find sequences in number arrays & convert to range (e.g. 100,2,3,4,5,101 -> 100,"2..5",101)

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Util::Range - Find sequences in number arrays & convert to range (e.g. 100,2,3,4,5,101 -> 100,"2..5",101)

=head1 VERSION

This document describes version 0.006 of Number::Util::Range (from Perl distribution Number-Util-Range), released on 2023-09-08.

=head1 FUNCTIONS


=head2 convert_number_sequence_to_range

Usage:

 convert_number_sequence_to_range(%args) -> any

Find sequences in number arrays & convert to range (e.g. 100,2,3,4,5,101 -E<gt> 100,"2..5",101).

Examples:

=over

=item * basic, non-numbers ignored:

 convert_number_sequence_to_range(array => [100, 2 .. 5, 101, "foo"]); # -> [100, "2..5", 101, "foo"]

=item * option: separator:

 convert_number_sequence_to_range(array => [100, 2 .. 5, 101], separator => "-"); # -> [100, "2-5", 101]

=item * multiple ranges, negative number:

 convert_number_sequence_to_range(array => [100, 2 .. 6, 101, 102, -5 .. -2, 103]);

Result:

 [100, "2..6", 101, 102, "-5..-2", 103]

=item * option: min_range_len (1):

 convert_number_sequence_to_range(array => [100, 2 .. 5, 101], min_range_len => 5); # -> [100, 2 .. 5, 101]

=item * option: min_range_len (2):

 convert_number_sequence_to_range(array => [100, 2, 3, 4, 101, "foo"], min_range_len => 3);

Result:

 [100, "2..4", 101, "foo"]

=item * option: ignore_duplicates:

 convert_number_sequence_to_range(array => [1 .. 4, 2, 9, 9, 9], ignore_duplicates => 1); # -> ["1..4", 9]

=item * option: max_range_len (1):

 convert_number_sequence_to_range(array => [98, 100 .. 110, 5, 101], max_range_len => 4);

Result:

 [98, "100..103", "104..107", 108, 109, 110, 5, 101]

=back

This routine accepts an array, finds sequences of numbers in it (e.g. 1, 2, 3),
and converts each sequence into a range ("1..3"). So basically it "compresses" the
sequence (many elements) into a single element.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<array[str]>

(No description)

=item * B<ignore_duplicates> => I<true>

(No description)

=item * B<max_range_len> => I<posint>

Maximum number of items in a sequence to convert to a range. Sequence that has
more than this number of items might be split into two or more ranges.

=item * B<min_range_len> => I<posint> (default: 4)

Minimum number of items in a sequence to convert to a range. Sequence that has
less than this number of items will not be converted.

=item * B<separator> => I<str> (default: "..")

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Util-Range>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Util-Range>.

=head1 SEE ALSO

L<Data::Dump> also does something similar when dumping arrays of numbers, e.g.
if you say C<dd [1,2,3,4];> it will dump the array as "[1..4]".

L<String::Util::Range> also convert sequences of letters to range (e.g.
"a","b","c","d" -> "a..d").

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Philippe Bruhat (BooK)

Philippe Bruhat (BooK) <book@cpan.org>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Util-Range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
