package Regexp::NumRange;

use 5.006;
use strict;
use warnings;
use Carp;
use POSIX qw( ceil );

use base 'Exporter';
our @EXPORT_OK = qw( rx_range rx_max );

=head1 NAME

Regexp::NumRange - Create Regular Expressions for numeric ranges

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

B<Regexp::NumRange> is a package for generating regular expression strings. These strings can be used in a regular expression to correctly match numeric strings within only a specified range.

Example Usage:

  use Test::More;
  use Regexp::NumRange qw/ rx_max /;

  my $rx = rx_max(255);

  like '100', qr/^$rx$/, '100 is less than 255';
  unlike '256', qr/^$rx$/, '256 is greater tha 255';

=head1 EXPORT

Exports Available:

  use Regexp::NumRange qw/ rx_max rx_range /;

=head1 SUBROUTINES/METHODS

=head2 rx_range

Create a regex string between two arbitrary integers.

  use Test::More;
  use Regexp::NumRange qw/ rx_range /;

  my $string = rx_range(256, 1024);
  my $rx = qr/^$string$/;

  ok "10" !~ $rx;
  ok "300" =~ $rx;
  ok "2000" !~ $rx;

=cut

sub rx_range {
    my ( $s, $e ) = @_;
    $s = int($s);
    $e = int($e);
    ( $s, $e ) = ( $e, $s ) if $e < $s;
    return rx_max($e) if $s == 0;

    my @ds = split //, "$s";
    my @de = split //, "$e";

    my $maxd = scalar @de;
    my $mind = scalar @ds;
    my $diff = $maxd - $mind;

    my $rx = '(';

    # after last significant digit
    my @l = @de;
    my $a = 0;
    if ( $diff || $de[0] - $ds[0] >= 1 ) {
        while ( scalar(@l) >= 2 ) {
            my $d = pop @l;
            my $ld = ( $a == 0 ) ? $d : $d - 1;
            next if $ld < 0;
            $rx .= join( '', @l );
            $rx .= "[0-$ld]";
            $rx .= "[0-9]" if $a >= 1;
            $rx .= "{$a}"  if $a > 1;
            $rx .= '|';
            $a++;
        }
    }

    # counting up to common digits
    if ($diff) {
        my $min = $ds[0] + 1;
        if ( $min <= 9 ) {
            my $n = $mind - 1;
            $rx .= "[$min-9]";
            $rx .= "[0-9]{$n}" if $n >= 1;
            $rx .= '|';
        }
    }
    elsif ( $de[0] - $ds[0] > 1 ) {

        # betwixt same digit
        my $n  = $mind - 1;
        my $d1 = $ds[0] + 1;
        my $d2 = $de[0] - 1;
        $rx .= "[$d1-$d2]";
        $rx .= "[0-9]{$n}" if $n >= 1;
        $rx .= '|';
    }

    # lowest digit
    {
        my $m  = $mind - 2;
        my $l  = $ds[-1];
        my $md = ( $ds[0] == $de[0] && !$diff ) ? $de[-1] : 9;
        $rx .= join( '', @ds[ 0 .. $m ] );
        $rx .= "[$l-$md]";
        $rx .= '|';
    }

    # full middle digit ranges
    my $om = -1;
    while ( $diff > 1 ) {
        my $m = $maxd - $diff + 1;
        my $r = ( $m == $maxd - 1 ) ? $de[0] - 1 : 9;
        $diff--;
        if ( $r <= 0 ) {
            $r = 9;
            $m--;
        }
        $rx .= "[1-$r]" if $r >= 1;
        $rx .= '[0-9]';
        $rx .= "{$m}"   if $r > 1;
        $rx .= '|';
        $om = $m;
    }
    if ( $diff == 1 ) {
        my $m = $maxd - 1;
        my $r = $de[0] - 1;
        if ( $m == $om ) {
            $r = 9;
            $m = $mind;
        }
        if ( $r >= 1 ) {
            $rx .= "[1-$r]";
            $rx .= "[0-9]" if $m >= 1;
            $rx .= "{$m}" if $m > 1;
            $rx .= '|';
        }
        $m--;
    }

    $rx =~ s/\|$//;
    $rx .= ')';
    return $rx;
}

=head2 rx_max

Create a regex string between 0 and an arbitrary integer.

  my $rx_string = rx_max(1024); # create a string matching numbers between 0 and 1024
  is $rx_string, '(102[0-4]|10[0-1][0-9]|0?[0-9]{1,3})';

=cut

sub rx_max {
    my ($max) = @_;
    $max = int($max);
    return "[0-$max]" if $max <= 9;
    my $rx     = '(';
    my @digits = split //, "$max";
    my $after  = 0;
    while ( scalar(@digits) ) {
        $after++;
        my $d     = pop @digits;
        my $ld    = ( $after == 1 ) ? $d : $d - 1;
        my $first = scalar(@digits) ? 0 : 1;
        next if $ld < 0 && $after > 1 && !$first;
        $rx .= join( '', @digits );
        $rx .= ( $ld < 1 ) ? '0' : "[0-$ld]";
        $rx .= $first      ? '?' : '';
        $rx .= "[0-9]" if $after > 1;
        $rx .= $first ? '{1,' : '{' if $after > 2;
        $rx .= ( $after - 1 ) . '}' if $after > 2;
        $rx .= '|' unless $first;
    }
    return $rx . ')';
}

1;

__END__

=head1 SEE ALSO

L<Regexp::Common::number> - more variations, but restricted to number of digit matching

L<http://dev.perl.org/perl6/rfc/197.html> - same goal, but for perl6!

=head1 AUTHOR

Jacob R Rideout, C<< <cpan at jacobrideout.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-regexp-numrange at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-NumRange>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

Fork on github: L<https://github.com/jrideout/Regexp-NumRange>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-NumRange>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regexp-NumRange>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regexp-NumRange>

=item * Search CPAN

L<http://search.cpan.org/dist/Regexp-NumRange/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to L<Module::Install>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jacob R Rideout.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

