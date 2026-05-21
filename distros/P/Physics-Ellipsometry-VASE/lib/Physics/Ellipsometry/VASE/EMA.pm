package Physics::Ellipsometry::VASE::EMA;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Exporter 'import';

our @EXPORT_OK = qw(ema_linear ema_bruggeman ema_maxwell_garnett ema_looyenga);

our $VERSION = '1.03';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::EMA - Effective Medium Approximation mixing
models for composite thin films

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::EMA qw(ema_linear ema_bruggeman
                                             ema_maxwell_garnett ema_looyenga);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);

    my $lambda = sequence(500) * 2 + 300;    # 300–1298 nm

    # Dielectric functions of two constituent materials
    my ($n_a, $k_a) = cauchy_nk($lambda, 1.46, 0.003, 0.0);  # SiO2
    my ($n_b, $k_b) = (ones($lambda), zeroes($lambda));       # void (air)

    my $eps_a = ($n_a + i() * $k_a) ** 2;
    my $eps_b = ($n_b + i() * $k_b) ** 2;

    # 30% porosity via Bruggeman mixing
    my $eps_eff = ema_bruggeman($eps_a, $eps_b, 0.30);
    my $N_eff   = sqrt($eps_eff);
    my $n_eff   = $N_eff->re;
    my $k_eff   = $N_eff->im->abs;

    printf "n(500 nm) = %.3f  (bulk SiO2 ≈ 1.46)\n",
           $n_eff->at(100);

=head1 DESCRIPTION

Many thin films encountered in ellipsometry are not homogeneous
single-phase materials.  Surface roughness, porosity, inter-diffusion
layers, nano-composites, and graded interfaces are all cases where
the optical response arises from a B<mixture> of two (or more)
constituent materials at a scale smaller than the wavelength of light.

B<Effective Medium Approximation> (EMA) theories provide the dielectric
function of such a composite given the dielectric functions of the
constituents and their volume fractions.  The choice of EMA model
depends on the microstructure:

=over 4

=item *

B<Linear> — simplest volume-weighted average; reasonable when the
constituents have similar dielectric functions.

=item *

B<Bruggeman> — symmetric in both constituents; no distinction between
host and inclusion.  Best for random mixtures, porous films, and
surface roughness layers.

=item *

B<Maxwell-Garnett> — asymmetric; treats one material as isolated
spherical inclusions in a continuous host matrix.  Best when the
volume fraction of the inclusion is small (< 30%).

=back

All three functions operate on the B<dielectric function> ε = N²
(not on n and k directly), because the mixing rules are derived in
terms of ε.

=head2 Surface roughness modelling

A common use is modelling surface roughness as a 50/50 Bruggeman mix
of the underlying film material and void:

    my $eps_rough = ema_bruggeman($eps_film, $eps_void, 0.50);

This roughness layer is then included in the TMM stack with a
thickness on the order of the RMS roughness.

=head1 FUNCTIONS

=head2 ema_linear

    my $eps_eff = ema_linear($eps_a, $eps_b, $vf);

B<Linear (volume-weighted) mixing>:

    ε_eff = (1 − f) · ε_a  +  f · ε_b

where C<$vf> (f) is the volume fraction of material B.  This is the
simplest mixing rule and does not account for local-field effects.
It is exact when the two phases form a laminar (layered) structure
with the electric field parallel to the layers.

    # 20% TiO2 in SiO2 matrix (linear blend)
    my $eps_mix = ema_linear($eps_sio2, $eps_tio2, 0.20);

=head2 ema_bruggeman

    my $eps_eff = ema_bruggeman($eps_a, $eps_b, $vf);

B<Bruggeman EMA> solves the self-consistent equation:

    f_a · (ε_a − ε_eff)/(ε_a + 2·ε_eff)
    + f_b · (ε_b − ε_eff)/(ε_b + 2·ε_eff)  =  0

For a two-component system this has the closed-form solution:

    ε_eff = ( b + sqrt(b² + 8·ε_a·ε_b) ) / 4

    where  b = (3f − 1)·ε_b + (2 − 3f)·ε_a

The implementation selects the root with positive real part to ensure
a physically meaningful result.

Bruggeman EMA is B<symmetric>: neither material is privileged as host
or inclusion.  This makes it the standard choice for:

=over 4

=item * Surface roughness layers (50% film / 50% void)

=item * Porous films (variable void fraction)

=item * Interdiffusion or intermixed interfaces

=item * Cermet and nano-composite films

=back

    # Surface roughness: 50% Ta2O5 + 50% void
    my $eps_void = ones($lambda) + i() * zeroes($lambda);  # ε = 1
    my $eps_rough = ema_bruggeman($eps_ta2o5, $eps_void, 0.50);

    # Include as a thin layer in the TMM stack
    my ($psi, $delta) = psi_delta($lambda, $theta,
        [$N_air, sqrt($eps_rough), $N_ta2o5, $N_si],
        [2.0, 100.0],   # 2 nm roughness, 100 nm film
    );

=head2 ema_maxwell_garnett

    my $eps_eff = ema_maxwell_garnett($eps_host, $eps_incl, $vf);

B<Maxwell-Garnett EMA> treats material B as dilute spherical inclusions
embedded in a continuous host matrix of material A:

    ε_eff = ε_a · (ε_b + 2ε_a + 2f·(ε_b − ε_a))
                 / (ε_b + 2ε_a −  f·(ε_b − ε_a))

This model is B<asymmetric>: swapping host and inclusion gives a
different result.  It is most accurate when the inclusion volume
fraction is below about 30% and the inclusions are well separated.

Typical applications:

=over 4

=item * Metal nanoparticles in a dielectric (Au in SiO2)

=item * Quantum dots in a polymer matrix

=item * Dilute dopant phases

=back

    # 5% Au nanoparticles in SiO2 host
    my $eps_composite = ema_maxwell_garnett($eps_sio2, $eps_au, 0.05);

=head1 CONVERTING BETWEEN ε AND N

The functions accept and return the complex dielectric function
ε = ε₁ + iε₂.  To convert to/from the complex refractive index
N = n + ik:

    # N → ε
    my $eps = ($n + i() * $k) ** 2;

    # ε → N
    my $N_complex = sqrt($eps);
    my $n = $N_complex->re;
    my $k = $N_complex->im->abs;

=head2 ema_looyenga

    my $eps_eff = ema_looyenga($eps_a, $eps_b, $volume_fraction_b);

The B<Looyenga mixing rule> (1965) uses cube-root averaging:

    eps_eff^(1/3) = (1-f)*eps_a^(1/3) + f*eps_b^(1/3)

This formula treats both components symmetrically (unlike Maxwell-Garnett)
and is simpler than solving the self-consistent Bruggeman equation.  It
works well for random mixtures where neither material forms a clear
host-inclusion geometry.

B<When to use Looyenga:>

=over 4

=item - Random mixtures with comparable volume fractions of both phases

=item - Porous materials (e.g., porous Si, aerogels)

=item - Quick estimate without iterative solving

=back

B<Example:>

    # Porous silicon (50% Si / 50% void)
    my $eps_Si   = pdl(15.0) + i() * pdl(0.2);
    my $eps_void = pdl(1.0)  + i() * pdl(0.0);
    my $eps_eff  = ema_looyenga($eps_void, $eps_Si, 0.5);
    my $n_eff = sqrt($eps_eff)->re;    # ~2.35

    # Compare with Bruggeman for same system
    my $eps_brug = ema_bruggeman($eps_void, $eps_Si, 0.5);  # ~2.50

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::TMM>,
L<Physics::Ellipsometry::VASE::Dispersion>,
L<Physics::Ellipsometry::VASE::Materials>

D.E. Aspnes, "Local-field effects and effective-medium theory: A
microscopic perspective", I<Am. J. Phys.> B<50>, 704 (1982).

H. Fujiwara, I<Spectroscopic Ellipsometry: Principles and Applications>,
John Wiley E<amp> Sons, 2007, Chapter 5.

=cut

# Linear (volume-weighted) mixing: ε_eff = (1-f)ε_a + f·ε_b
sub ema_linear {
    my ($eps_a, $eps_b, $vf) = @_;
    return (1.0 - $vf) * $eps_a + $vf * $eps_b;
}

# Bruggeman EMA: f_a·(ε_a - ε_eff)/(ε_a + 2ε_eff) + f_b·(ε_b - ε_eff)/(ε_b + 2ε_eff) = 0
# Solved analytically for 2-component mixtures:
#   ε_eff = (b ± sqrt(b² + 8ε_aε_b)) / 4
#   where b = (3f_b - 1)ε_b + (3f_a - 1)ε_a = (3vf - 1)ε_b + (2 - 3vf)ε_a
sub ema_bruggeman {
    my ($eps_a, $eps_b, $vf) = @_;
    my $fa = 1.0 - $vf;

    # Quadratic solution for 2-component Bruggeman
    my $b = (3*$vf - 1) * $eps_b + (3*$fa - 1) * $eps_a;
    my $discriminant = $b**2 + 8 * $eps_a * $eps_b;

    # Take the root with positive real part
    my $sqrt_disc = sqrt($discriminant + i()*0);
    my $eps_eff = ($b + $sqrt_disc) / 4.0;

    # Ensure physical result (positive real part of ε)
    my $eps_eff2 = ($b - $sqrt_disc) / 4.0;
    my $use_alt = ($eps_eff->re < 0) & ($eps_eff2->re > 0);
    if (ref $use_alt && $use_alt->any) {
        my $idx = which($use_alt);
        $eps_eff->index($idx) .= $eps_eff2->index($idx);
    }

    return $eps_eff;
}

# Maxwell-Garnett EMA: inclusion (b) in host matrix (a)
# ε_eff = ε_a · (ε_b + 2ε_a + 2f(ε_b - ε_a)) / (ε_b + 2ε_a - f(ε_b - ε_a))
sub ema_maxwell_garnett {
    my ($eps_a, $eps_b, $vf) = @_;

    my $numer = $eps_b + 2*$eps_a + 2*$vf*($eps_b - $eps_a);
    my $denom = $eps_b + 2*$eps_a -   $vf*($eps_b - $eps_a);

    return $eps_a * $numer / $denom;
}

# Looyenga EMA: ε_eff^(1/3) = (1-f)·ε_a^(1/3) + f·ε_b^(1/3)
# Valid for random mixtures where neither component is clearly host/inclusion.
# More symmetric than Maxwell-Garnett; simpler than Bruggeman.
sub ema_looyenga {
    my ($eps_a, $eps_b, $vf) = @_;
    my $fa = 1.0 - $vf;

    # Cube root of complex numbers: |z|^(1/3) * exp(i*arg(z)/3)
    my $eps_a_third = _complex_cbrt($eps_a);
    my $eps_b_third = _complex_cbrt($eps_b);

    my $mix = $fa * $eps_a_third + $vf * $eps_b_third;

    # Cube the result
    return $mix**3;
}

# Complex cube root: z^(1/3)
sub _complex_cbrt {
    my ($z) = @_;
    my $mag = abs($z);
    my $arg = carg($z);
    return $mag**(1.0/3.0) * (cos($arg/3.0) + i() * sin($arg/3.0));
}

1;
