package String::LCSS;

use warnings;
use strict;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(lcss);

our $VERSION = '1.00';

sub lcss {
    my $solns0 = (_lcss($_[0], $_[1]))[0];
    return unless $solns0;
    my @match = @{ $solns0 };
    return if length $match[0] == 1;
    return wantarray ? @match : $match[0];
}

sub _lcss {
    # Return array-of-arrays of longest substrings and indices
    my( $r1, $r2 ) = @_;
    my( $l1, $l2, $swap ) = ( length $r1, length $r2, 0 );
    ( $r1, $r2, $l1, $l2, $swap ) = ( $r2, $r1, $l2, $l1, 1 ) if $l1 > $l2;

    my( $best, @solns ) = 0;
    for my $start ( 0 .. $l2 - 1 ) {
        for my $l ( reverse 1 .. $l1 - $start ) {
            my $substr = substr( $r1, $start, $l );
            my $o = index( $r2, $substr );
            next if $o < 0;
            if( $l > $best ) {
                $best = length $substr;
                @solns = [ $substr, $start, $o ];
            }
            elsif( $l == $best ) {
                push @solns, [ $substr, $start, $o ];
            }
        }
    }
    return @solns;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################



=head1 NAME

String::LCSS - Find The Longest Common Substring of Two Strings.

=head1 VERSION

This document refers to String::LCSS version 1.00.

=head1 SYNOPSIS

    use String::LCSS;
    my $longest = lcss( "zyzxx", "abczyzefg" );
    print $longest, "\n";

    my @result = lcss( "zyzxx", "abczyzefg" );
    print "$result[0] ($result[1],$result[2])\n";

=head1 DESCRIPTION

String::LCSS provides the function C<lcss> to ferret out the longest common
substring shared by two strings passed as arguments.

=head1 SUBROUTINES

=over 4

=item lcss($string1, $string2)

C<undef> is returned if the susbstring length is one char or less.

In scalar context, returns the substring.

When used in an array context, C<lcss> will return the indexi of the match
root in the two args.

=back

=head1 EXPORT

The C<lcss> function is exported by default.

=head1 BUGS

There are no known bugs in this module.

=head1 SEE ALSO

L<String::LCSS_XS> is not pure Perl, but it was created to be faster.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See L<perlartistic|perlartistic>.

=head1 AUTHOR

The original author is Daniel Yacob (CPAN ID: DYACOB).

Gene Sullivan (gsullivan@cpan.org) is a co-maintainer.

=head1 ACKNOWLEDGEMENTS

Code provided by BrowserUk from PerlMonks.

=cut

