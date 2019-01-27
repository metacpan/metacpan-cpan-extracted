package String::Util::Range;

our $DATE = '2019-01-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(convert_sequence_to_range);
our %SPEC;

$SPEC{'convert_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in arrays & convert to range '.
        '(e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")',
    description => <<'_',

Sequence follows Perl's autoincrement notion, e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

_
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
            summary => 'option: separator',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                separator => '-',
            },
            result => ["1-4","x","a-d"],
        },
        {
            summary => 'option: threshold',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d","e"],
                threshold => 5,
            },
            result => [1,2,3,4, "x", "a..e"],
        },
    ],
};
sub convert_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $threshold = $args{threshold} // 4;
    my $separator = $args{separator} // '..';

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $threshold ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    for my $i (0..$#{$array}) {
        my $el = $array->[$i];
        if (@buf) {
            (my $buf_inc = $buf[-1])++;
            if ($el ne $buf_inc) { # breaks current sequence
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

This document describes version 0.001 of String::Util::Range (from Perl distribution String-Util-Range), released on 2019-01-25.

=head1 FUNCTIONS


=head2 convert_sequence_to_range

Usage:

 convert_sequence_to_range(%args) -> any

Find sequences in arrays & convert to range (e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x").

Examples:

=over

=item * basic:

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "d"]); # -> ["1..4", "x", "a..d"]

=item * option: separator:

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "d"], separator => "-"); # -> ["1-4", "x", "a-d"]

=item * option: threshold:

 convert_sequence_to_range(array => [1 .. 4, "x", "a" .. "e"], threshold => 5); # -> [1 .. 4, "x", "a..e"]

=back

Sequence follows Perl's autoincrement notion, e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<array[str]>

=item * B<separator> => I<str> (default: "..")

=item * B<threshold> => I<posint> (default: 4)

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Util-Range>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Util-Range>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Util-Range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump> also does something similar, e.g. if you say C<< dd
[1,2,3,4,"x","a","b","c","d"]; >> it will dump the array as C<< "[1 .. 4, "x",
"a" .. "d"]" >>.

L<Number::Util::Range> which only deals with numbers.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
