package Physics::CVD::Film;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Film analysis for CVD-grown films
#
# Computes:
#   - Thickness, roughness, density, porosity
#   - Composition profile (depth-resolved)
#   - Stoichiometry analysis
#   - Export to XYZ and LAMMPS formats
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        lattice       => $opts{lattice},
        surface       => $opts{surface},
        site_species  => $opts{site_species},
        lattice_size  => $opts{lattice_size} // [30, 30, 20],
        lattice_const => $opts{lattice_const} // 3.0,  # Angstrom
    }, $class;
    return $self;
}

sub thickness {
    my ($self) = @_;
    my ($nx, $ny) = @{$self->{lattice_size}};
    my $sum = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            $sum += $self->{surface}[$x][$y];
        }
    }
    my $avg_layers = $sum / ($nx * $ny);
    return $avg_layers * $self->{lattice_const} / 10.0;  # nm
}

sub roughness {
    my ($self) = @_;
    my ($nx, $ny) = @{$self->{lattice_size}};
    my $sum = 0;
    my $sum2 = 0;
    my $n = $nx * $ny;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            my $h = $self->{surface}[$x][$y];
            $sum  += $h;
            $sum2 += $h * $h;
        }
    }
    my $mean = $sum / $n;
    my $var  = $sum2 / $n - $mean * $mean;
    $var = 0 if $var < 0;
    return sqrt($var) * $self->{lattice_const} / 10.0;  # nm
}

sub density {
    my ($self) = @_;
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my $max_z = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            $max_z = max($max_z, $self->{surface}[$x][$y]);
        }
    }
    return 0 if $max_z == 0;

    my $occupied = 0;
    my $total = $nx * $ny * $max_z;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            for my $z (0 .. $max_z-1) {
                $occupied++ if $self->{lattice}[$x][$y][$z];
            }
        }
    }
    return $occupied / $total;
}

sub porosity { return 1.0 - $_[0]->density }

# Composition analysis: count each species type
sub composition {
    my ($self) = @_;
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my %counts;
    my $total = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            for my $z (0 .. $nz-1) {
                next unless $self->{lattice}[$x][$y][$z];
                my $sp = $self->{site_species}[$x][$y][$z] // 'unknown';
                $counts{$sp}++;
                $total++;
            }
        }
    }
    # Convert to fractions
    my %fractions;
    for my $sp (keys %counts) {
        $fractions{$sp} = $counts{$sp} / $total if $total > 0;
    }
    return { counts => \%counts, fractions => \%fractions, total => $total };
}

# Depth-resolved composition profile
sub composition_profile {
    my ($self, %opts) = @_;
    my $bin_size = $opts{bin_size} // 1;  # layers per bin
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};

    my @profile;
    for (my $z = 0; $z < $nz; $z += $bin_size) {
        my %counts;
        my $total = 0;
        for my $x (0 .. $nx-1) {
            for my $y (0 .. $ny-1) {
                for my $dz (0 .. $bin_size-1) {
                    my $zz = $z + $dz;
                    last if $zz >= $nz;
                    next unless $self->{lattice}[$x][$y][$zz];
                    my $sp = $self->{site_species}[$x][$y][$zz] // 'unknown';
                    $counts{$sp}++;
                    $total++;
                }
            }
        }
        last if $total == 0;
        my %fracs;
        for my $sp (keys %counts) {
            $fracs{$sp} = $counts{$sp} / $total;
        }
        push @profile, {
            depth_nm => $z * $self->{lattice_const} / 10.0,
            total    => $total,
            fractions => \%fracs,
        };
    }
    return \@profile;
}

# Stoichiometry ratio (e.g., Si:O ratio for SiO₂)
sub stoichiometry {
    my ($self, $elem_a, $elem_b) = @_;
    my $comp = $self->composition;
    my $ca = $comp->{counts}{$elem_a} // 0;
    my $cb = $comp->{counts}{$elem_b} // 0;
    return ($cb > 0) ? $ca / $cb : 0;
}

# Export film to XYZ format
sub export_xyz {
    my ($self, $filename) = @_;
    $filename //= 'cvd_film.xyz';
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my $a = $self->{lattice_const};

    my @atoms;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            for my $z (0 .. $nz-1) {
                next unless $self->{lattice}[$x][$y][$z];
                my $sp = $self->{site_species}[$x][$y][$z] // 'X';
                push @atoms, [$sp, $x*$a, $y*$a, $z*$a];
            }
        }
    }

    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    printf $fh "%d\n", scalar @atoms;
    printf $fh "CVD film: %s\n", join(', ', map { $_->[0] } @atoms[0..min(2,$#atoms)]);
    for my $atom (@atoms) {
        printf $fh "%-4s %10.4f %10.4f %10.4f\n", @$atom;
    }
    close $fh;
    return scalar @atoms;
}

# Export to LAMMPS data format
sub export_lammps_data {
    my ($self, $filename) = @_;
    $filename //= 'cvd_film.data';
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my $a = $self->{lattice_const};

    # Collect atoms and unique species
    my @atoms;
    my %type_map;
    my $type_id = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            for my $z (0 .. $nz-1) {
                next unless $self->{lattice}[$x][$y][$z];
                my $sp = $self->{site_species}[$x][$y][$z] // 'X';
                $type_map{$sp} //= ++$type_id;
                push @atoms, [$type_map{$sp}, $x*$a, $y*$a, $z*$a];
            }
        }
    }

    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    printf $fh "CVD Film - LAMMPS data file\n\n";
    printf $fh "%d atoms\n", scalar @atoms;
    printf $fh "%d atom types\n\n", $type_id;
    printf $fh "0.0 %.4f xlo xhi\n", $nx * $a;
    printf $fh "0.0 %.4f ylo yhi\n", $ny * $a;
    printf $fh "0.0 %.4f zlo zhi\n", $nz * $a;
    printf $fh "\nAtoms\n\n";
    for my $i (0 .. $#atoms) {
        printf $fh "%d %d %.4f %.4f %.4f\n", $i+1, @{$atoms[$i]};
    }
    close $fh;
    return scalar @atoms;
}

1;
