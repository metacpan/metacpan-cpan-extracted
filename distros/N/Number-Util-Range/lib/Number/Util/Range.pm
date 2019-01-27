package Number::Util::Range;

our $DATE = '2019-01-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
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
    },
    result_naked => 1,
    examples => [
        {
            args => {
                array => [100, 2, 3, 4, 5, 101, 'foo'],
            },
            result => [100, "2..5", 101, 'foo'],
        },
    ],
};
sub convert_number_sequence_to_range {
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

This document describes version 0.001 of Number::Util::Range (from Perl distribution Number-Util-Range), released on 2019-01-25.

=head1 FUNCTIONS


=head2 convert_number_sequence_to_range

Usage:

 convert_number_sequence_to_range(%args) -> any

Find sequences in number arrays & convert to range (e.g. 100,2,3,4,5,101 -> 100,"2..5",101).

Examples:

=over

=item * Example #1:

 convert_number_sequence_to_range(array => [100, 2 .. 5, 101, "foo"]); # -> [100, "2..5", 101, "foo"]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<array[str]>

=item * B<separator> => I<str> (default: "..")

=item * B<threshold> => I<posint> (default: 4)

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Util-Range>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Util-Range>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Util-Range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump> also does something similar when dumping arrays of numbers, e.g.
if you say C<dd [1,2,3,4];> it will dump the array as "[1..4]".

L<String::Util::Range>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
