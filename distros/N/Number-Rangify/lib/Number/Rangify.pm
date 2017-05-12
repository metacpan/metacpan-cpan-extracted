use 5.008;
use strict;
use warnings;

package Number::Rangify;
our $VERSION = '1.100860';
# ABSTRACT: Optimize a list of values into ranges
use Set::IntRange;
use Exporter qw(import);
our %EXPORT_TAGS = (util => [qw(rangify)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub rangify {

    # each @range element is a [ $lower, $upper ] array ref.
    my @ranges;
  VAL: for my $val (sort { $a <=> $b } @_) {
        for my $range (@ranges) {

            # is the value already in the range?
            next VAL if $val >= $range->[0] && $val <= $range->[1];

            # extend the range downwards or upwards?
            if ($val == $range->[0] - 1) {
                $range->[0]--;
                next VAL;
            } elsif ($val == $range->[1] + 1) {
                $range->[1]++;
                next VAL;
            }
        }

        # still here? make a new range
        push @ranges, [ $val, $val ];
    }
    my @range_obj = map { Set::IntRange->new(@$_) } @ranges;
    wantarray ? @range_obj : \@range_obj;
}
1;


__END__
=pod

=for stopwords rangify

=head1 NAME

Number::Rangify - Optimize a list of values into ranges

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    use Number::Rangify 'rangify';

    my @list = (1, 2, 3, 5, 7, 9, 10, 11, 15);
    my @ranges = rangify(@list);
    for my $range (@ranges) {
        printf "%s-%s\n", $range->Size;
    }

=head1 DESCRIPTION

This module provides a function that can optimize a list of values into range
objects.

=head1 FUNCTIONS

=head2 rangify

Takes a list of values and makes them into ranges.

For example:

    rangify(1, 2, 3, 5, 7, 9, 10, 11, 15);

returns the following ranges:

    1-3
    5-5
    7-7
    9-11
    15-15

It returns a list (in list context) or an array reference (in scalar context)
of L<Set::IntRange> objects.

Duplicate values in the input list are ignored.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Number-Rangify>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Number-Rangify/>.

The development version lives at
L<http://github.com/hanekomu/Number-Rangify/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

