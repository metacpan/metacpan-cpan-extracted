package RackMan::Utils;

use strict;
use warnings;

use Algorithm::Diff ();
use Carp;
use Exporter ();
use Term::ANSIColor qw< CLEAR GREEN RED >;


use constant {
    DIFF_CONTEXT    => 3,
    CHUNK_SEPARATOR => '@@',
};

our @ISA = qw< Exporter >;
our @EXPORT = qw< diff_lines parse_regexp >;


#
# diff_lines()
# ----------
sub diff_lines {
    my ($input_A, $input_B, $opts) = @_;

    croak "error: input A is expected as an arrayref"
        if ref $input_A ne "ARRAY";
    croak "error: input B is expected as an arrayref"
        if ref $input_B ne "ARRAY";
    croak "error: options are expected as a hashref"
        if ref $opts and ref $opts ne "HASH";

    # default values
    $opts ||= {};
    $opts->{input_A_header} ||= "Current configuration";
    $opts->{input_B_header} ||= "Expected configuration";

    # computes the differences between the two input
    my @lines = Algorithm::Diff::sdiff($input_A, $input_B);

    # Note: We use Algorithm::Diff::sdiff() instead of Text::Diff::diff()
    # because we want to ignore blank lines, an option not provided by
    # Text::Diff (as of v1.41).

    # do we want colours?
    my %x = ( "+" => GREEN,  "-" => RED,  R => CLEAR );

    my @ctx;
    my $last_diff = DIFF_CONTEXT;
    my $chunk_no  = 0;
    my @diff;

    # construct the output
    for my $line (@lines) {
        # a line is an arrayref with the following elements:
        # - modifier, "+" (addition), "-" (deletion), "c" (change),
        #   "u" (unmodified)
        # - old value
        # - new value
        #
        # see Algorithm::Diff documentation for more details

        if ($line->[0] eq "+" and length $line->[2]) {
            # push the "before-change" context, and the new line
            push @diff, CHUNK_SEPARATOR."\n" if $chunk_no > 1;
            push @diff, @ctx, "$x{$line->[0]}$line->[0]$line->[2]$x{R}\n";
            @ctx = ();
            $last_diff = 0;
            $chunk_no++;
        }

        if ($line->[0] eq "-" and length $line->[1]) {
            # push the "before-change" context, and the old line
            push @diff, CHUNK_SEPARATOR."\n" if $chunk_no > 1;
            push @diff, @ctx, "$x{$line->[0]}$line->[0]$line->[1]$x{R}\n";
            @ctx = ();
            $last_diff = 0;
            $chunk_no++;
        }

        if ($line->[0] eq "c" and length $line->[1]) {
            # push the "before-change" context, the old line and the new line
            push @diff, CHUNK_SEPARATOR."\n" if $chunk_no > 1;
            push @diff, @ctx, "$x{'-'}-$line->[1]\n$x{'+'}+$line->[2]$x{R}\n";
            @ctx = ();
            $last_diff = 0;
            $chunk_no++;
        }

        if ($line->[0] eq "u") {
            # accumulate diff context, no more than DIFF_CONTEXT lines
            push @ctx, " $line->[1]\n";
            shift @ctx while @ctx > DIFF_CONTEXT;
            $last_diff++;

            if ($last_diff == DIFF_CONTEXT) {
                # push "after-change" context
                push @diff, @ctx;
                @ctx = ();
            }
        }
    }

    # add the diff headers
    @diff and unshift @diff, 
        "$x{'-'}--- $opts->{input_A_header}$x{R}\n",
        "$x{'+'}+++ $opts->{input_B_header}$x{R}\n";

    return wantarray ? @diff : \@diff
}


#
# parse_regexp()
# ------------
sub parse_regexp {
    my ($text) = @_;
    my $flags = "";

    if ($text =~ m:^/:) {
        $text =~ s:^/::;
        $text =~ s:/(\w+)?$::;
        $flags = "(?:$1)" if defined $1;
    }

    my $re = eval { qr/$flags$text/ };
    (my $err = $@) =~ s/ at .* line \d+\.//;

    return wantarray ? ($re, $err) : $re
}


__PACKAGE__

__END__

=head1 NAME

RackMan::Utils - Utility functions

=head1 DESCRIPTION

This module contains several utility functions, grouped here to avoid
duplicated code.


=head1 FUNCTIONS

=head2 diff_lines()

Compute the differences between two input files (given as arrayrefs)
using Algorithm::Diff, and return the result as an array. Color codes
are added if the output is a terminal.

B<Arguments:>

=over

=item 1. first input file (mandatory, arrayref)

=item 2. second input file (mandatory, arrayref)

=item 3. options (hashref)

=over

=item *

C<input_A_header> - set the diff header for input A

=item *

C<input_B_header> - set the diff header for input B

=back

=back

B<Return:>

=over

=item *

diff result (array in list context, arrayref in scalar context)

=back


=head2 parse_regexp()

Parse the given string and return the corresponding Perl regexp (C<qr//>).

B<Arguments:>

=over

=item 1. input string

=back

B<Return:>

=over

=item * in scalar context: the resulting regexp

=item * in list context: the resulting regexp, parsing error

=back


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

