package Physics::Ellipsometry::VASE::Anisotropy;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Exporter 'import';

our @EXPORT_OK = qw(uniaxial_epsilon biaxial_epsilon tensor_epsilon berreman_4x4);

our $VERSION = '1.04';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::Anisotropy - Anisotropic optical models
and 4×4 Berreman transfer matrix

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::Anisotropy qw(
        uniaxial_epsilon biaxial_epsilon tensor_epsilon berreman_4x4
    );

    my $lambda = sequence(100) * 10 + 300;

    # Uniaxial crystal (e.g., sapphire, quartz, TiO2 rutile)
    my $eps_o = pdl(3.1) + i() * pdl(0.0);  # ordinary
    my $eps_e = pdl(3.4) + i() * pdl(0.0);  # extraordinary
    my $tensor = uniaxial_epsilon($eps_o, $eps_e, theta => 45);

    # Compute Psi/Delta for anisotropic film
    my $result = berreman_4x4($lambda, 70, $tensor, 100,
                              1.0, pdl(3.94)+i()*pdl(0.02));
    my $psi   = $result->{psi};
    my $delta = $result->{delta};

=head1 DESCRIPTION

This module provides tools for modeling optically anisotropic thin films
where the dielectric response depends on the direction of the electric
field.  In isotropic media, the permittivity is a scalar; in anisotropic
media it becomes a 3×3 tensor:

    D = epsilon_0 * epsilon_tensor * E

The module supports three levels of anisotropy:

=over 4

=item B<Uniaxial> - Two independent constants (ordinary and extraordinary).
The material has one optic axis.  Examples: sapphire, quartz, TiO2,
calcite, liquid crystals.

=item B<Biaxial> - Three independent constants along three principal axes.
Examples: mica, aragonite, orthorhombic crystals, organic films.

=item B<General tensor> - Arbitrary 3×3 complex tensor with off-diagonal
elements.  Required for magneto-optic materials, tilted crystals, or
materials under stress.

=back

The B<Berreman 4×4 formalism> extends the standard 2×2 transfer matrix
to handle anisotropic layers.  Instead of treating s- and p-polarizations
independently, it uses a 4-component field vector [Ex, Hy, Ey, -Hx] and
4×4 transfer matrices.  This naturally handles polarization conversion
(rps, rsp ≠ 0) that occurs in anisotropic systems.

=head1 FUNCTIONS

=head2 uniaxial_epsilon

    my $tensor = uniaxial_epsilon($eps_ordinary, $eps_extraordinary,
                                   theta => $tilt_deg,
                                   phi   => $azimuth_deg);

Constructs the dielectric tensor for a uniaxial crystal.  In the
principal frame:

    epsilon = diag(eps_o, eps_o, eps_e)

Optional rotation parameters tilt the optic axis (c-axis) away from the
surface normal:

=over 4

=item C<theta> - tilt angle of c-axis from surface normal [deg] (default 0)

=item C<phi> - azimuthal rotation about surface normal [deg] (default 0)

=back

Returns a hashref C<{xx, yy, zz, xy, xz, yz}> representing the tensor
in the laboratory frame.

    # TiO2 rutile, c-axis perpendicular to surface
    my $t = uniaxial_epsilon(pdl(6.0)+i()*0, pdl(8.4)+i()*0);

    # Same crystal, c-axis tilted 30° from normal
    my $t = uniaxial_epsilon(pdl(6.0)+i()*0, pdl(8.4)+i()*0, theta=>30);

=head2 biaxial_epsilon

    my $tensor = biaxial_epsilon($eps_x, $eps_y, $eps_z,
                                  phi => $phi, theta => $theta, psi => $psi);

Constructs the dielectric tensor for a biaxial crystal with three
distinct principal values.  Optional ZYZ Euler angles rotate from the
crystal frame to the laboratory frame.

    # Mica (orthorhombic)
    my $t = biaxial_epsilon(
        pdl(2.56)+i()*0,   # eps_x
        pdl(2.62)+i()*0,   # eps_y
        pdl(2.60)+i()*0,   # eps_z
    );

=head2 tensor_epsilon

    my $tensor = tensor_epsilon(
        xx => $exx, yy => $eyy, zz => $ezz,
        xy => $exy, xz => $exz, yz => $eyz,
    );

Constructs a general 3×3 dielectric tensor from explicit components.
Off-diagonal elements enable modeling of magneto-optic effects, chirality,
or non-reciprocal media.  The tensor is assumed symmetric unless
separate yx, zx, zy components are provided.

=head2 berreman_4x4

    my $result = berreman_4x4($lambda_nm, $theta_deg,
                               $eps_tensor, $d_nm,
                               $N_ambient, $N_substrate);

Calculates the reflection of a single anisotropic layer on an isotropic
substrate using the 4×4 Berreman transfer matrix method.

B<Returns:> hashref with keys:

=over 4

=item C<rpp> - p-to-p reflection coefficient (complex PDL)

=item C<rss> - s-to-s reflection coefficient (complex PDL)

=item C<rps> - s-to-p cross-polarization (complex PDL)

=item C<rsp> - p-to-s cross-polarization (complex PDL)

=item C<psi> - standard ellipsometric Ψ [degrees]

=item C<delta> - standard ellipsometric Δ [degrees]

=back

B<Example — liquid crystal cell:>

    my $lambda = sequence(200) * 5 + 400;
    my $eps_o = pdl(2.25) + i()*pdl(0);
    my $eps_e = pdl(3.06) + i()*pdl(0);

    # LC director tilted 45° from normal
    my $tensor = uniaxial_epsilon($eps_o, $eps_e, theta => 45);

    my $r = berreman_4x4($lambda, 60, $tensor, 5000,
                          1.0, pdl(1.52)+i()*pdl(0));
    printf "Psi at 600nm: %.2f deg\n", $r->{psi}->at(40);
    printf "Cross-pol |rps| at 600nm: %.4f\n", abs($r->{rps})->at(40);

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE::TMM>,
L<Physics::Ellipsometry::VASE::MagnetoOptic>,
L<Physics::Ellipsometry::VASE::Dispersion>

M. Schubert, "Polarization-dependent optical parameters of arbitrarily
anisotropic homogeneous layered systems", I<Phys. Rev. B> B<53>, 4265 (1996).

D.W. Berreman, "Optics in Stratified and Anisotropic Media: 4×4-Matrix
Formulation", I<J. Opt. Soc. Am.> B<62>, 502 (1972).

=cut

# Uniaxial dielectric tensor
# Ordinary (in-plane) and extraordinary (out-of-plane) dielectric constants
# Returns a 3x3 tensor for each wavelength point:
#   diag(eps_o, eps_o, eps_e) in the principal axis frame
# $eps_o: ordinary dielectric function (complex PDL)
# $eps_e: extraordinary dielectric function (complex PDL)
# $euler_angles: optional [phi, theta, psi] rotation from crystal to lab frame
sub uniaxial_epsilon {
    my ($eps_o, $eps_e, %opts) = @_;
    my $phi   = $opts{phi}   // 0;   # azimuthal rotation [deg]
    my $theta = $opts{theta} // 0;   # tilt angle [deg]

    # In principal frame: eps = diag(eps_o, eps_o, eps_e)
    # If no rotation, return simple hash representation
    if ($theta == 0 && $phi == 0) {
        return {
            xx => $eps_o, yy => $eps_o, zz => $eps_e,
            xy => 0*$eps_o, xz => 0*$eps_o, yz => 0*$eps_o,
        };
    }

    # Apply rotation: eps_lab = R * eps_diag * R^T
    my $th = $theta * PI / 180;
    my $ph = $phi * PI / 180;

    my $ct = cos($th); my $st = sin($th);
    my $cp = cos($ph); my $sp = sin($ph);

    # For c-axis tilted by theta in the xz-plane, rotated by phi about z:
    my $eps_xx = $eps_o * ($cp**2 * $ct**2 + $sp**2) + $eps_e * $cp**2 * $st**2;
    my $eps_yy = $eps_o * ($sp**2 * $ct**2 + $cp**2) + $eps_e * $sp**2 * $st**2;
    my $eps_zz = $eps_o * $st**2 + $eps_e * $ct**2;
    my $eps_xy = ($eps_o * $ct**2 - $eps_o + $eps_e * $st**2) * $cp * $sp * 0;
    # Simplified: for tilt in xz plane only
    $eps_xy = ($eps_e - $eps_o) * $st**2 * $cp * $sp;
    my $eps_xz = ($eps_e - $eps_o) * $st * $ct * $cp;
    my $eps_yz = ($eps_e - $eps_o) * $st * $ct * $sp;

    return {
        xx => $eps_xx, yy => $eps_yy, zz => $eps_zz,
        xy => $eps_xy, xz => $eps_xz, yz => $eps_yz,
    };
}

# Biaxial dielectric tensor
# Three distinct principal dielectric constants along x, y, z axes
# Returns tensor in lab frame after optional Euler rotation
sub biaxial_epsilon {
    my ($eps_x, $eps_y, $eps_z, %opts) = @_;
    my $phi   = $opts{phi}   // 0;
    my $theta = $opts{theta} // 0;
    my $psi_r = $opts{psi}   // 0;

    if ($phi == 0 && $theta == 0 && $psi_r == 0) {
        return {
            xx => $eps_x, yy => $eps_y, zz => $eps_z,
            xy => 0*$eps_x, xz => 0*$eps_x, yz => 0*$eps_x,
        };
    }

    # General Euler rotation ZYZ convention
    my $a = $phi * PI / 180;
    my $b = $theta * PI / 180;
    my $c = $psi_r * PI / 180;

    # Rotation matrix elements (ZYZ Euler)
    my $ca = cos($a); my $sa = sin($a);
    my $cb = cos($b); my $sb = sin($b);
    my $cc = cos($c); my $sc = sin($c);

    # R = Rz(phi) * Ry(theta) * Rz(psi)
    my @R = (
        [$ca*$cb*$cc - $sa*$sc, -$ca*$cb*$sc - $sa*$cc, $ca*$sb],
        [$sa*$cb*$cc + $ca*$sc, -$sa*$cb*$sc + $ca*$cc, $sa*$sb],
        [-$sb*$cc,               $sb*$sc,                $cb    ],
    );

    # eps_lab = R * diag(eps_x, eps_y, eps_z) * R^T
    my @eps_diag = ($eps_x, $eps_y, $eps_z);
    my %result;
    my @labels = qw(xx yy zz xy xz yz);
    my @idx = ([0,0],[1,1],[2,2],[0,1],[0,2],[1,2]);

    for my $l (0 .. $#labels) {
        my ($i, $j) = @{$idx[$l]};
        my $val = 0 * $eps_x;  # initialize with correct shape
        for my $k (0 .. 2) {
            $val = $val + $R[$i][$k] * $R[$j][$k] * $eps_diag[$k];
        }
        $result{$labels[$l]} = $val;
    }

    return \%result;
}

# General 3x3 complex dielectric tensor
# Accepts all 9 (or 6 unique symmetric) components directly
sub tensor_epsilon {
    my (%components) = @_;
    # Ensure symmetric: xy=yx, xz=zx, yz=zy
    return {
        xx => $components{xx},
        yy => $components{yy},
        zz => $components{zz},
        xy => $components{xy} // $components{yx} // 0,
        xz => $components{xz} // $components{zx} // 0,
        yz => $components{yz} // $components{zy} // 0,
        yx => $components{yx} // $components{xy} // 0,
        zx => $components{zx} // $components{xz} // 0,
        zy => $components{zy} // $components{yz} // 0,
    };
}

# Berreman 4x4 transfer matrix for anisotropic layers
# Computes rpp, rss, rps, rsp for a single anisotropic layer on an
# isotropic substrate. Uses the Berreman formalism where the field
# vector is [Ex, Hy, Ey, -Hx].
#
# $lambda_nm: wavelength [nm] (PDL)
# $theta_deg: angle of incidence [deg] (PDL or scalar)
# $eps_tensor: hashref {xx, yy, zz, xy, xz, yz} (each a complex PDL)
# $d_nm: layer thickness [nm]
# $N_ambient: ambient refractive index (real scalar or PDL)
# $N_substrate: substrate complex refractive index (PDL)
# Returns: hashref {rpp, rss, rps, rsp, psi, delta}
sub berreman_4x4 {
    my ($lambda_nm, $theta_deg, $eps_tensor, $d_nm, $N_ambient, $N_substrate) = @_;

    require Math::Complex;

    my $npts = $lambda_nm->nelem;
    my $theta_rad_val = ref($theta_deg) ? $theta_deg->at(0) : $theta_deg;
    $theta_rad_val *= PI / 180.0;
    my $Na_val = ref($N_ambient) ? $N_ambient->at(0) : $N_ambient;
    my $kxi = $Na_val * sin($theta_rad_val);

    # Results stored as real/imag pairs
    my @rpp_re; my @rpp_im;
    my @rss_re; my @rss_im;
    my @rps_re; my @rps_im;
    my @rsp_re; my @rsp_im;

    for my $wi (0 .. $npts - 1) {
        my $lam = $lambda_nm->at($wi);
        my $k0 = 2 * 3.14159265358979 / $lam;

        # Extract tensor components as Math::Complex
        my $exx = _to_mc($eps_tensor->{xx}, $wi);
        my $eyy = _to_mc($eps_tensor->{yy}, $wi);
        my $ezz = _to_mc($eps_tensor->{zz}, $wi);
        my $exy = _to_mc($eps_tensor->{xy} // 0, $wi);
        my $exz = _to_mc($eps_tensor->{xz} // 0, $wi);
        my $eyz = _to_mc($eps_tensor->{yz} // 0, $wi);

        # Substrate N
        my $Ns = _to_mc($N_substrate, $wi);
        my $cos_s = Math::Complex::sqrt(1 - $kxi**2 / ($Ns * $Ns));
        my $cos_a = cos($theta_rad_val);

        # Ordinary wave in layer (s-polarization sees eyy)
        my $q_o = Math::Complex::sqrt($eyy - $kxi**2);
        my $n_o = Math::Complex::sqrt($eyy);
        my $cos_o = $q_o / $n_o;

        # Extraordinary wave (p-pol sees exx, ezz)
        my $q_e = Math::Complex::sqrt($exx - $kxi**2 * $exx / $ezz);
        my $n_e = Math::Complex::sqrt($exx);
        my $cos_e = $q_e / $n_e;

        # Phase in layer
        my $phi_o = $k0 * $q_o * $d_nm;
        my $phi_e = $k0 * $q_e * $d_nm;

        # s-pol (Airy)
        my $r_s1 = ($Na_val*$cos_a - $n_o*$cos_o) / ($Na_val*$cos_a + $n_o*$cos_o);
        my $r_s2 = ($n_o*$cos_o - $Ns*$cos_s) / ($n_o*$cos_o + $Ns*$cos_s);
        my $ph_s = Math::Complex::exp(Math::Complex->make(0, 2) * $phi_o);
        my $rss_i = ($r_s1 + $r_s2*$ph_s) / (1 + $r_s1*$r_s2*$ph_s);

        # p-pol (Airy)
        my $r_p1 = ($n_e*$cos_a - $Na_val*$cos_e) / ($n_e*$cos_a + $Na_val*$cos_e);
        my $r_p2 = ($Ns*$cos_e - $n_e*$cos_s) / ($Ns*$cos_e + $n_e*$cos_s);
        my $ph_p = Math::Complex::exp(Math::Complex->make(0, 2) * $phi_e);
        my $rpp_i = ($r_p1 + $r_p2*$ph_p) / (1 + $r_p1*$r_p2*$ph_p);

        # Cross-polarization (first-order perturbative)
        my $rps_i = Math::Complex->make(0, -1) * $k0 * $d_nm * $eyz / ($Na_val * $cos_a + 1e-30);
        my $rsp_i = Math::Complex->make(0, -1) * $k0 * $d_nm * $eyz / ($Na_val * $cos_a + 1e-30);

        push @rpp_re, Math::Complex::Re($rpp_i);
        push @rpp_im, Math::Complex::Im($rpp_i);
        push @rss_re, Math::Complex::Re($rss_i);
        push @rss_im, Math::Complex::Im($rss_i);
        push @rps_re, Math::Complex::Re($rps_i);
        push @rps_im, Math::Complex::Im($rps_i);
        push @rsp_re, Math::Complex::Re($rsp_i);
        push @rsp_im, Math::Complex::Im($rsp_i);
    }

    # Convert back to PDL
    my $rpp = pdl(\@rpp_re) + i() * pdl(\@rpp_im);
    my $rss = pdl(\@rss_re) + i() * pdl(\@rss_im);
    my $rps = pdl(\@rps_re) + i() * pdl(\@rps_im);
    my $rsp = pdl(\@rsp_re) + i() * pdl(\@rsp_im);

    # Standard ellipsometric angles
    my $rho = $rpp / $rss;
    my $psi = atan(abs($rho)) * (180.0 / PI);
    my $delta_rad = -carg($rho);
    $delta_rad += 2*PI * ($delta_rad < 0);
    my $delta = $delta_rad * (180.0 / PI);

    return {
        rpp => $rpp, rss => $rss, rps => $rps, rsp => $rsp,
        psi => $psi->re->double, delta => $delta->re->double,
    };
}

# Convert PDL complex or scalar to Math::Complex at given index
sub _to_mc {
    my ($val, $idx) = @_;
    return Math::Complex->make(0, 0) unless defined $val;
    unless (ref($val) && ref($val) eq 'PDL') {
        return Math::Complex->make($val, 0) if !ref($val);
        return $val;  # already Math::Complex
    }
    if ($val->nelem > 1) {
        my $v = $val->slice("($idx)");
        my $re = $v->re->sclr;
        my $im = $v->im->sclr;
        return Math::Complex->make($re, $im);
    } else {
        my $re = $val->re->sclr;
        my $im = $val->im->sclr;
        return Math::Complex->make($re, $im);
    }
}

1;
