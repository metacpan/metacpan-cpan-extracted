package Physics::Ellipsometry::VASE::Materials;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Exporter 'import';

our @EXPORT_OK = qw(load_material interpolate_material);

our $VERSION = '1.03';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::Materials - Load and interpolate tabulated
optical constants

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::Materials qw(load_material
                                                   interpolate_material);

    # Load a Woollam .mat file (auto-detects eV↔nm)
    my $si = load_material('Si_jaw.mat');

    printf "Material : %s\n",   $si->{name};
    printf "Points   : %d\n",   $si->{npts};
    printf "Range    : %.1f – %.1f nm\n", $si->{wav_min}, $si->{wav_max};

    # Interpolate onto the measurement wavelength grid
    my $lambda = sequence(500) * 2 + 300;        # 300–1298 nm
    my ($n_si, $k_si) = interpolate_material($si, $lambda);

    # Build the complex refractive index for TMM
    my $N_si = $n_si + i() * $k_si;

=head1 DESCRIPTION

In spectroscopic ellipsometry the optical model usually contains at
least one material whose refractive index is not described by a simple
parametric formula but is instead given as a table of measured values —
for example, a crystalline silicon substrate or a metal reference layer.
These are called B<point-by-point> (PBP) optical constants.

Physics::Ellipsometry::VASE::Materials loads such tabulated data from
disk and provides linear interpolation to an arbitrary wavelength grid,
so the constants can be used directly by L<Physics::Ellipsometry::VASE::TMM>
or any model function.

When a file stores its spectral axis in electron-volts (eV) the module
converts automatically to nanometres via

    λ (nm) = 1239.842 / E (eV)

and reverses the data order if necessary to ensure wavelengths are
ascending.

=head1 SUPPORTED FORMATS

=head2 Woollam .mat format

The standard format produced by WVASE® and CompleteEASE.  The file has a
three-line header followed by data columns:

    silicon
    eV
    469
    0.6199  3.939  0.0240
    0.6250  3.941  0.0242
    ...

=over 4

=item Line 1 — material name (free text)

=item Line 2 — spectral units: C<nm> or C<eV>

=item Line 3 — number of data points

=item Data — three whitespace-separated columns: wavelength (or energy),
I<n>, I<k>

=back

=head2 Generic 3-column format

A plain text file with three whitespace-separated columns (wavelength in
nm, I<n>, I<k>).  Comment lines beginning with C<#> and blank lines are
skipped.  No header is required.

    # wavelength(nm)  n       k
    300.0              1.540   0.000
    310.0              1.538   0.000
    ...

=head1 FUNCTIONS

=head2 load_material

    my $mat = load_material($filepath);

Reads a tabulated optical-constants file and returns a hashref with:

=over 4

=item C<name> — material name (from header, or filename for generic files)

=item C<wavelength> — PDL piddle of wavelengths in nm (ascending order)

=item C<n> — PDL piddle of refractive index values

=item C<k> — PDL piddle of extinction coefficient values

=item C<npts> — number of data points

=item C<wav_min> — shortest wavelength (nm)

=item C<wav_max> — longest wavelength (nm)

=back

The format (Woollam vs generic) is auto-detected.  If the file stores
data in eV the conversion to nm is performed automatically.

    my $ta = load_material('ta_pbp.mat');
    my $sio2 = load_material('SiO2_Palik.dat');

=head2 interpolate_material

    my ($n, $k) = interpolate_material($material, $lambda_nm);

Linearly interpolates the tabulated I<n> and I<k> values in C<$material>
(as returned by L</load_material>) onto the wavelength grid
C<$lambda_nm>.

B<Important:> the target wavelengths should lie within the range
C<[wav_min, wav_max]> of the loaded material.  Values outside this range
are extrapolated linearly, which may be inaccurate.

    my $lambda = sequence(500) * 2 + 300;
    my ($n, $k) = interpolate_material($ta, $lambda);

    # Use in a TMM calculation
    my $N_sub = $n + i() * $k;

=head1 TYPICAL WORKFLOW

    use Physics::Ellipsometry::VASE::Materials qw(load_material
                                                   interpolate_material);
    use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);

    # 1. Load substrate from a .mat file
    my $sub = load_material('Si_jaw.mat');

    # 2. Define measurement grid
    my $lambda = sequence(400) * 2.5 + 300;
    my $theta  = ones($lambda) * 70;

    # 3. Interpolate substrate onto measurement grid
    my ($n_sub, $k_sub) = interpolate_material($sub, $lambda);
    my $N_sub = $n_sub + i() * $k_sub;

    # 4. Film from a parametric model
    my ($n_film, $k_film) = cauchy_nk($lambda, 1.46, 0.003, 0.0);
    my $N_film = $n_film + i() * $k_film;

    # 5. Ambient
    my $N_air = ones($lambda) + i() * zeroes($lambda);

    # 6. Calculate Psi/Delta
    my ($psi, $delta) = psi_delta($lambda, $theta,
        [$N_air, $N_film, $N_sub], [100.0]);

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::TMM>,
L<Physics::Ellipsometry::VASE::Dispersion>

=cut

sub load_material {
    my ($filepath) = @_;
    open my $fh, '<', $filepath or die "Cannot open material file $filepath: $!";
    my @lines = <$fh>;
    close $fh;

    # Strip Windows CR from all lines
    s/\r//g for @lines;
    chomp @lines;

    my ($name, $units, $npts);
    my @data;

    # Detect format by checking header
    if (@lines >= 3 && $lines[1] =~ /^\s*(nm|eV)\s*$/i) {
        # Woollam .mat format
        $name  = $lines[0];
        $units = lc($lines[1]);
        $units =~ s/\s+//g;
        $npts  = $lines[2] + 0 if $lines[2] =~ /^\d+/;

        for my $i (3 .. $#lines) {
            next if $lines[$i] =~ /^\s*$/;
            my @fields = split /\s+/, $lines[$i];
            next unless @fields >= 3 && $fields[0] =~ /^[-+]?\d/;
            push @data, [@fields[0..2]];
        }
    } else {
        # Generic 3-column format
        $name  = $filepath;
        $units = 'nm';
        for my $line (@lines) {
            next if $line =~ /^\s*#/;
            next if $line =~ /^\s*$/;
            my @fields = split /\s+/, $line;
            next unless @fields >= 3 && $fields[0] =~ /^[-+]?\d/;
            push @data, [@fields[0..2]];
        }
    }

    die "No data found in $filepath" unless @data;

    my $arr = pdl \@data;
    my $wav = $arr->(0,:)->flat->sever;
    my $n   = $arr->(1,:)->flat->sever;
    my $k   = $arr->(2,:)->flat->sever;

    # Convert eV to nm if needed
    if ($units eq 'ev') {
        $wav = 1239.842 / $wav;
        # Reverse if now in descending order
        if ($wav->at(0) > $wav->at(-1)) {
            $wav = $wav->(-1:0)->sever;
            $n   = $n->(-1:0)->sever;
            $k   = $k->(-1:0)->sever;
        }
    }

    return {
        name       => $name,
        wavelength => $wav,
        n          => $n,
        k          => $k,
        npts       => $wav->nelem,
        wav_min    => $wav->min->sclr,
        wav_max    => $wav->max->sclr,
    };
}

# Interpolate material optical constants to a given wavelength grid
sub interpolate_material {
    my ($material, $lambda_nm) = @_;
    my $n = $lambda_nm->interpol($material->{wavelength}, $material->{n});
    my $k = $lambda_nm->interpol($material->{wavelength}, $material->{k});
    return ($n, $k);
}

1;
