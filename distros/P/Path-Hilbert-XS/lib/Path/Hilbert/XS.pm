package Path::Hilbert::XS;
use strict;
use warnings;
use XSLoader;
use parent 'Exporter';

our $VERSION = '0.003';
our @EXPORT  = qw<d2xy xy2d>;

XSLoader::load( 'Path::Hilbert::XS', $VERSION );

1;

__END__

=encoding utf8

=head1 NAME

Path::Hilbert::XS - XS implementation of a Hilbert Path algorithm

=head1 VERSION

0.003

=head1 SYNOPSIS

    use Path::Hilbert::XS;

    my ($x, $y) = d2xy(16, 127);
    my $d = xy2d(16, $x, $y);
    die unless $d == 127;

=head1 DESCRIPTION

This implements L<Path::Hilbert> in XS for speed and awesomesauceness.

The OO interface is not available (yet?).

=head1 WHY

While L<Path::Hilbert> is a solid module, we just wanted speed when dealing
with abundant amount of data.

Here are some statistics, generated using the bundled F<tools/benchmark.pl>
script:

    -- d2xy --
    PP: Rounded run time per iteration: 1.4496e-05 +/- 4.8e-08 (0.3%)
    XS: Rounded run time per iteration: 5.1150e-07 +/- 6.3e-10 (0.1%)

        Time       PP      XS
    PP  1.450e-05  --      -3.53%
    XS  5.115e-07  96.47%  --

    -- xy2d--
    PP: Rounded run time per iteration: 1.3215e-05 +/- 2.7e-08 (0.2%)
    XS: Rounded run time per iteration: 4.7877e-07 +/- 8.3e-10 (0.2%)

        Time       PP      XS
    PP  1.322e-05  --      -3.62%
    XS  4.788e-07  96.38%  --

(Statistics collected using L<Dumbbench>.)

            Rate    PP    XS
    PP   71028/s    --  -98%
    XS 3703704/s 5114%    --

(Statistics collected using L<Benchmark>.)

=head1 CREDITS

=over 4

=item * Rafaël Garcia-Suarez - for asking for it.

=item * p5pclub

=back

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Sawyer X C<< xsawyerx AT cpan DOT org >>

=back

