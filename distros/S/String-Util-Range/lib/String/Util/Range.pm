package String::Util::Range;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-08'; # DATE
our $DIST = 'String-Util-Range'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(convert_sequence_to_range);

our %SPEC;

$SPEC{'convert_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in arrays & convert to range '.
        '(e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")',
    description => <<'_',

This routine accepts an array, finds sequences in it (e.g. 1, 2, 3 or aa, ab,
ac, ad), and converts each sequence into a range ("1..3" or "aa..ad"). So
basically it "compresses" the sequence (many elements) into a single element.

What determines a sequence is Perl's autoincrement magic (see the `perlop`
documentation on the Auto-increment), e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

_
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
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
            schema => ['posint*', min=>2],
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
            summary => 'basic',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
            },
            result => ["1..4","x","a..d"],
        },
        {
            summary => 'option: min_range_len (1)',
            args => {
                array => [1,2,3, "x", "a","b","c"],
                min_range_len => 3,
            },
            result => ["1..3","x","a..c"],
        },
        {
            summary => 'option: min_range_len (2)',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                min_range_len => 5,
            },
            result => [1,2,3,4,"x","a","b","c","d"],
        },
        {
            summary => 'option: max_range_len',
            args => {
                array => [1,2,3,4,5,6,7, "x", "a","b","c","d","e","f","g"],
                min_range_len => 3,
                max_range_len => 3,
            },
            result => ["1..3","4..6",7,"x","a..c","d..f","g"],
        },
        {
            summary => 'option: separator',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                separator => '-',
            },
            result => ["1-4","x","a-d"],
        },
        {
            summary => 'option: ignore_duplicates',
            args => {
                array => [1, 2, 3, 4, 2, 9, 9, 9, "a","a","a"],
                ignore_duplicates => 1,
            },
            result => ["1..4", 9,"a"],
        },
    ],
};
sub convert_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $min_range_len = $args{min_range_len} //
        $args{threshold} # old name, DEPRECATED
        // 4;
    my $max_range_len = $args{max_range_len};
    die "max_range_len must be >= min_range_len"
        if defined($max_range_len) && $max_range_len < $min_range_len;
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

        if (@buf) {
            (my $buf_inc = $buf[-1])++;
            if ($el ne $buf_inc) { # breaks current sequence
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

# ABSTRACT: Find sequences in arrays & convert to range (e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Util::Range - Find sequences in arrays & convert to range (e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")

=head1 VERSION

This document describes version 0.002 of String::Util::Range (from Perl distribution String-Util-Range), released on 2023-09-08.

=head1 FUNCTIONS


=head2 convert_sequence_to_range

Usage:

 convert_sequence_to_range(%args) -> any

Find sequences in arrays & convert to range (e.g. "a","b","c","d","x",1,2,3,4,"x" -E<gt> "a..d","x","1..4","x").

Examples:

=over

=item * basic:

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "d"]); # -> ["1..4", "x", "a..d"]

=item * option: min_range_len (1):

 convert_sequence_to_range(array => [1, 2, 3, "x", "a", "b", "c"], min_range_len => 3); # -> ["1..3", "x", "a..c"]

=item * option: min_range_len (2):

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "d"], min_range_len => 5); # -> [1 .. 4, "x", "a" .. "d"]

=item * option: max_range_len:

 convert_sequence_to_range(
   array => [1 .. 7, "x", "a" .. "g"],
   max_range_len => 3,
   min_range_len => 3
 );

Result:

 ["1..3", "4..6", 7, "x", "a..c", "d..f", "g"]

=item * option: separator:

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "d"], separator => "-"); # -> ["1-4", "x", "a-d"]

=item * option: ignore_duplicates:

 convert_sequence_to_range(
   array => [1 .. 4, 2, 9, 9, 9, "a", "a", "a"],
   ignore_duplicates => 1
 );

Result:

 ["1..4", 9, "a"]

=back

This routine accepts an array, finds sequences in it (e.g. 1, 2, 3 or aa, ab,
ac, ad), and converts each sequence into a range ("1..3" or "aa..ad"). So
basically it "compresses" the sequence (many elements) into a single element.

What determines a sequence is Perl's autoincrement magic (see the C<perlop>
documentation on the Auto-increment), e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

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

Please visit the project's homepage at L<https://metacpan.org/release/String-Util-Range>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Util-Range>.

=head1 SEE ALSO

L<Data::Dump> also does something similar, e.g. if you say C<< dd
[1,2,3,4,"x","a","b","c","d"]; >> it will dump the array as C<< "[1 .. 4, "x",
"a" .. "d"]" >>.

L<Number::Util::Range> which only deals with numbers.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Util-Range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
