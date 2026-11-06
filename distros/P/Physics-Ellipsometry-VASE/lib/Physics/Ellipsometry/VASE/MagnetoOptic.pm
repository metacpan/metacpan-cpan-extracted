package Physics::Ellipsometry::VASE::MagnetoOptic;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Exporter 'import';

our @EXPORT_OK = qw(magneto_optic_tensor kerr_rotation);

our $VERSION = '1.04';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::MagnetoOptic - Magneto-optic Kerr effect
(MOKE) models for spectroscopic ellipsometry

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::MagnetoOptic qw(
        magneto_optic_tensor kerr_rotation
    );

    my $lambda = sequence(100) * 10 + 400;

    # Construct MO dielectric tensor for a ferromagnet
    my $eps_d  = pdl(-13.8) + i()*pdl(15.7);   # diagonal (Fe at 633nm)
    my $eps_od = pdl(0.74)  + i()*pdl(0.21);   # off-diagonal (Q*N)
    my $tensor = magneto_optic_tensor($eps_d, $eps_od,
                                       geometry => 'polar');

    # Kerr rotation from a semi-infinite magnetic layer
    my ($theta_K, $eta_K) = kerr_rotation($lambda, 65,
        eps_diag => pdl(-13.8)+i()*pdl(15.7),
        Q        => pdl(0.04)+i()*pdl(0.006),
        geometry => 'polar',
    );

=head1 DESCRIPTION

The magneto-optic Kerr effect (MOKE) describes the change in
polarization state of light upon reflection from a magnetized material.
It is widely used for magnetic thin film characterization and has three
geometries:

=over 4

=item B<Polar MOKE> - Magnetization perpendicular to the surface
(along z).  Produces Kerr rotation in the reflected beam for both
s- and p-polarized light.  Typically the largest signal.

=item B<Longitudinal MOKE> - Magnetization in the surface plane,
within the plane of incidence (along x).  Produces rotation
proportional to cos(θ).

=item B<Transverse MOKE> - Magnetization in the surface plane,
perpendicular to the plane of incidence (along y).  Changes only
the p-polarized reflectance amplitude (no rotation; changes Δ only).

=back

The magneto-optic response is described by the Voigt parameter Q,
which quantifies the ratio of off-diagonal to diagonal permittivity:

    epsilon_xy = i * Q * epsilon_xx

The full dielectric tensor for polar geometry:

           ⎡ ε_xx   iQε    0  ⎤
    ε  =   ⎢-iQε   ε_yy    0  ⎥
           ⎣  0      0    ε_zz ⎦

For longitudinal geometry, the off-diagonal elements appear in the
xz and zx positions.

=head1 FUNCTIONS

=head2 magneto_optic_tensor

    my $tensor = magneto_optic_tensor($eps_diag, $eps_offdiag,
                                       geometry => 'polar');

Constructs the 3×3 dielectric tensor with magneto-optic off-diagonal
elements.

B<Parameters:>

=over 4

=item C<$eps_diag> - diagonal permittivity component(s) (complex PDL or scalar)

=item C<$eps_offdiag> - off-diagonal permittivity (= i*Q*eps_diag for polar)

=item C<geometry> - 'polar', 'longitudinal', or 'transverse'

=back

B<Returns:> hashref C<{xx, yy, zz, xy, xz, yz}> suitable for use with
C<berreman_4x4>.

    # Fe at 633 nm (polar magnetization)
    my $t = magneto_optic_tensor(
        pdl(-13.8) + i()*pdl(15.7),
        pdl(0.74) + i()*pdl(0.21),
        geometry => 'polar',
    );
    # $t->{xy} contains the off-diagonal element

=head2 kerr_rotation

    my ($theta_K, $eta_K) = kerr_rotation($lambda_nm, $theta_deg, %params);

Calculates the complex Kerr angle (rotation + ellipticity) for
reflection from a semi-infinite magnetized medium.

For polar MOKE at oblique incidence:

    θ_K + i*η_K = -i * Q * N * cos(θ_t)
                  / ((ε - 1) * cos(θ_m))

where θ_t is the refraction angle inside the medium and θ_m depends on
the geometry.

B<Parameters:>

=over 4

=item C<eps_diag> - diagonal dielectric constant (complex)

=item C<Q> - Voigt magneto-optic parameter (complex)

=item C<geometry> - 'polar' (default), 'longitudinal', or 'transverse'

=back

B<Returns:> two PDL piddles:

=over 4

=item C<$theta_K> - Kerr rotation angle [millidegrees]

=item C<$eta_K> - Kerr ellipticity [millidegrees]

=back

B<Example — spectral Kerr rotation of iron:>

    use Physics::Ellipsometry::VASE::MagnetoOptic qw(kerr_rotation);

    my $lambda = sequence(50) * 20 + 400;  # 400-1380 nm

    # Fe optical and MO constants (energy-dependent)
    my $E = 1240.0 / $lambda;  # eV
    my $eps = pdl(-13.8) + i()*pdl(15.7);  # simplified constant
    my $Q = pdl(0.04) + i()*pdl(0.006);

    my ($theta, $eta) = kerr_rotation($lambda, 0,
        eps_diag => $eps,
        Q        => $Q,
        geometry => 'polar',
    );
    printf "Kerr rotation at 633nm: %.1f mdeg\n", $theta->at(11);
    printf "Kerr ellipticity at 633nm: %.1f mdeg\n", $eta->at(11);

=head1 NOTES

=over 4

=item * Kerr rotation angles are typically small (0.01-1°), requiring
sensitive detection (modulation techniques, lock-in amplifiers).

=item * For multilayer magnetic structures, combine with
L<Physics::Ellipsometry::VASE::Anisotropy/berreman_4x4> using the
tensor from C<magneto_optic_tensor>.

=item * Typical Voigt parameters: Fe Q≈0.04, Co Q≈0.05, Ni Q≈0.02
at visible wavelengths.

=back

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE::Anisotropy>,
L<Physics::Ellipsometry::VASE::TMM>

P.M. Oppeneer, "Magneto-optical Kerr spectra", I<Handbook of Magnetic
Materials> B<13>, 229 (2001).

Z.Q. Qiu and S.D. Bader, "Surface magneto-optic Kerr effect",
I<Rev. Sci. Instrum.> B<71>, 1243 (2000).

=cut

# Magneto-optic dielectric tensor
# For a magnetized material, the permittivity tensor has off-diagonal
# components that depend on magnetization direction:
#
# For polar geometry (M || z, perpendicular to surface):
#   eps = [ eps_xx,  -i*Q*eps_xx,  0       ]
#         [ i*Q*eps_xx,  eps_xx,    0       ]
#         [ 0,           0,         eps_zz  ]
#
# For longitudinal geometry (M || y, in plane of incidence):
#   eps = [ eps_xx,  0,       i*Q*eps_xx  ]
#         [ 0,       eps_yy,  0           ]
#         [ -i*Q*eps_xx, 0,   eps_zz      ]
#
# Q = Voigt parameter (complex, wavelength-dependent)
# Returns tensor hashref compatible with Anisotropy::berreman_4x4
#
# $eps_diag: diagonal dielectric constant (complex PDL)
# $Q: Voigt magneto-optic parameter (complex PDL)
# $geometry: 'polar', 'longitudinal', or 'transverse'
sub magneto_optic_tensor {
    my ($eps_diag, $Q, %opts) = @_;
    my $geometry = $opts{geometry} // 'polar';

    my $zero = 0 * $eps_diag;
    my $off_diag = i() * $Q * $eps_diag;

    if ($geometry eq 'polar') {
        # M along z (surface normal)
        return {
            xx => $eps_diag,  yy => $eps_diag,  zz => $eps_diag,
            xy => -$off_diag, xz => $zero,      yz => $zero,
            yx => $off_diag,  zx => $zero,      zy => $zero,
        };
    }
    elsif ($geometry eq 'longitudinal') {
        # M along y (in-plane, in scattering plane)
        return {
            xx => $eps_diag,  yy => $eps_diag,  zz => $eps_diag,
            xy => $zero,      xz => $off_diag,  yz => $zero,
            yx => $zero,      zx => -$off_diag, zy => $zero,
        };
    }
    elsif ($geometry eq 'transverse') {
        # M along x (in-plane, perpendicular to scattering plane)
        return {
            xx => $eps_diag,  yy => $eps_diag,  zz => $eps_diag,
            xy => $zero,      xz => $zero,      yz => -$off_diag,
            yx => $zero,      zx => $zero,      zy => $off_diag,
        };
    }
    else {
        die "Unknown MO geometry: $geometry (use 'polar', 'longitudinal', 'transverse')";
    }
}

# Kerr rotation and ellipticity from reflection coefficients
# For the polar MOKE geometry on a semi-infinite magnetic substrate:
#
#   Kerr rotation: theta_K = -Re(rps/rpp)  [radians]
#   Kerr ellipticity: eta_K = -Im(rps/rpp) [radians]
#
# For a magnetic film on a non-magnetic substrate, the full Berreman
# 4x4 calculation is needed (use Anisotropy::berreman_4x4).
#
# This function provides the simple semi-infinite substrate formula:
#   r_ps/r_pp = -i*Q*n*cos(theta) / ((n^2-1)*(n^2*cos^2(theta) - 1)^(1/2))
#
# $lambda_nm: wavelength [nm]
# $theta_deg: angle of incidence [deg]
# $eps_diag: diagonal dielectric function of magnetic medium (complex PDL)
# $Q: Voigt parameter (complex PDL)
# Returns: hashref {theta_K => rotation [deg], eta_K => ellipticity [deg],
#                   rps_rpp => complex ratio}
sub kerr_rotation {
    my ($lambda_nm, $theta_deg, $eps_diag, $Q) = @_;

    require Math::Complex;

    my $npts = $lambda_nm->nelem;
    my $theta_rad = $theta_deg * PI / 180.0;
    my $cos_t = cos($theta_rad);
    my $sin_t = sin($theta_rad);

    # Complex refractive index of magnetic medium
    my $N = sqrt($eps_diag);

    # cos(theta_t) in the medium via Snell's law (assuming N_ambient=1)
    my $cos_t_m = sqrt(1.0 - $sin_t**2 / $eps_diag);

    # Polar Kerr: rps/rpp for semi-infinite magnetized substrate
    my $numerator = -i() * $Q * $N * $cos_t;
    my $denominator = ($eps_diag - 1.0) * $cos_t_m;

    my $ratio = $numerator / ($denominator + 1e-30);

    # Kerr angles
    my $theta_K = -$ratio->re * (180.0 / PI);  # rotation [deg]
    my $eta_K   = -$ratio->im * (180.0 / PI);  # ellipticity [deg]

    return {
        theta_K => $theta_K->double,
        eta_K   => $eta_K->double,
        rps_rpp => $ratio,
    };
}

1;
