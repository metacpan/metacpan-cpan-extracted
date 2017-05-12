package Sort::strverscmp;

require Sort::strverscmp::StringIterator;

use Exporter 'import';
use 5.010;

use strict;
use warnings;

our $VERSION = "0.014";
our @EXPORT = qw(strverscmp);
our @EXPORT_OK = qw(strverssort versionsort);

# strnum_cmp from bam_sort.c
sub strverscmp($$) {
    my $ai = Sort::strverscmp::StringIterator->new($_[0]);
    my $bi = Sort::strverscmp::StringIterator->new($_[1]);

    do {
        if (_isdigit($ai->head) && _isdigit($bi->head)) {
            my $an = (($ai->head . $ai->tail) =~ /^(\d*)/)[0];
            my $bn = (($bi->head . $bi->tail) =~ /^(\d*)/)[0];
            if ($an =~ /^0\d/ || $bn =~ /^0\d/) {
                return _fcmp($an, $bn);
            } else {
                if ($an <=> $bn) {
                    return ($an <=> $bn);
                }
            }
        } else {
            if ($ai->head cmp $bi->head) {
                return ($ai->head cmp $bi->head);
            }
        }
        $ai->advance();
        $bi->advance();
    } while (defined($ai->head) && defined($bi->head));

    return $ai->head ? 1 : $bi->head ? -1 : 0;
}

sub versionsort { &strverssort }
sub strverssort {
    return sort { strverscmp($a, $b) } @_;
}

sub _isdigit {
    my $c = shift;
    return (defined($c) && $c =~ /^\d+$/);
}

sub _fcmp {
    my ($l, $r) = @_;

    my ($lz, $ln, $rz, $rn);
    ($lz, $ln) = _decompose_fractional($l);
    ($rz, $rn) = _decompose_fractional($r);

    if (length($lz) == length($rz)) {
        return $ln <=> $rn;
    } else {
        return (length($lz) > length($rz) ? -1 : 1);
    }
}

sub _decompose_fractional {
    my ($zeroes, $number) = shift =~ /^(0*)(\d+)$/;
    return ($zeroes, $number);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sort::strverscmp -- Compare strings while treating digits characters numerically.

=head1 SYNOPSIS

  use Sort::strverscmp;
  my @version = qw(a A beta9 alpha9 alpha10 alpha010 1.0.5 1.05);
  my @sorted  = sort strverscmp @list;
  say join("\n", @sorted);

  if (strverscmp($min_version, $this_version) <= 0) {
    say 'this version satisfies minimum version';
  }

=head1 DESCRIPTION

Perl equivalents to GNU C<strverscmp> and C<versionsort>.

=head1 METHODS

=head2 strverscmp

  strverscmp('1.0.5', '1.0.50'); # -1

Returns -1, 0, or 1 depending on whether the left version string is less than,
equal to, or greater than the right version string.

=head2 versionsort

  versionsort('1.0.5', '1.0.50'); # -1

Returns a sorted list of version strings.

=head1 AUTHOR

Nathaniel Nutter C<nnutter@cpan.org>

=head1 COPYRIGHT AND DISCLAIMER

Copyright 2013, The Genome Institute at Washington University
C<nnutter@cpan.org>, all rights reserved.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for a
particular purpose.

=cut

