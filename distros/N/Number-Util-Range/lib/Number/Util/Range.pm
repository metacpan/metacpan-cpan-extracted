package Number::Util::Range;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-04'; # DATE
our $DIST = 'Number-Util-Range'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(convert_number_sequence_to_range);
our %SPEC;

$SPEC{'convert_number_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in number arrays & convert to range '.
        '(e.g. 100,2,3,4,5,101 -> 100,"2..5",101)',
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        threshold => {
            schema => 'posint*',
            default => 4,
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
            summary => 'option: threshold',
            args => {
                array => [100, 2, 3, 4, 5, 101],
                threshold => 5,
            },
            result => [100, 2, 3, 4, 5, 101],
        },
        {
            summary => 'option: ignore_duplicates',
            args => {
                array => [1, 2, 3, 4, 2, 9, 9, 9],
                ignore_duplicates => 1,
            },
            result => ["1..4", 9],
        },
    ],
};
sub convert_number_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $threshold = $args{threshold} // 4;
    my $separator = $args{separator} // '..';
    my $ignore_duplicates = $args{ignore_duplicates};

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $threshold ? ("$buf[0]$separator$buf[-1]") : @buf;
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

This document describes version 0.003 of Number::Util::Range (from Perl distribution Number-Util-Range), released on 2023-01-04.

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

=item * option: threshold:

 convert_number_sequence_to_range(array => [100, 2 .. 5, 101], threshold => 5); # -> [100, 2 .. 5, 101]

=item * option: ignore_duplicates:

 convert_number_sequence_to_range(array => [1 .. 4, 2, 9, 9, 9], ignore_duplicates => 1); # -> ["1..4", 9]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<array[str]>

(No description)

=item * B<ignore_duplicates> => I<true>

(No description)

=item * B<separator> => I<str> (default: "..")

(No description)

=item * B<threshold> => I<posint> (default: 4)

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

L<String::Util::Range>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Util-Range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
