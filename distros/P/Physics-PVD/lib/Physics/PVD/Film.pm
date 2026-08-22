package Physics::PVD::Film;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);
use POSIX qw(floor);

# ═══════════════════════════════════════════════════════════════════════════════
# Film data structure and analysis
#
# Represents a deposited thin film as a 3D lattice occupancy grid.
# Provides analysis methods: thickness, roughness, density, composition
# profiles, porosity, and export to various formats.
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        lattice_size  => $opts{lattice_size}  // [100, 100, 50],
        lattice_const => $opts{lattice_const} // 3.3,   # Angstrom
        lattice       => $opts{lattice}  // undef,
        surface       => $opts{surface}  // undef,
        species       => $opts{species}  // {},
        deposited     => $opts{deposited} // 0,
        atoms         => [],   # for explicit atom list mode
    }, $class;
    return $self;
}

# Add an atom explicitly (alternative to lattice mode)
sub add_atom {
    my ($self, %atom) = @_;
    push @{$self->{atoms}}, {
        species => $atom{species} // 'X',
        x       => $atom{x} // 0,
        y       => $atom{y} // 0,
        z       => $atom{z} // 0,
    };
    return $self;
}

# Average film thickness in nm
sub thickness {
    my ($self) = @_;
    if ($self->{surface}) {
        my ($nx, $ny) = @{$self->{lattice_size}};
        my $total_h = 0;
        for my $x (0 .. $nx-1) {
            for my $y (0 .. $ny-1) {
                $total_h += $self->{surface}[$x][$y];
            }
        }
        my $avg_layers = $total_h / ($nx * $ny);
        return $avg_layers * $self->{lattice_const} / 10.0;  # Å → nm
    }
    # From explicit atoms
    if (@{$self->{atoms}}) {
        my $max_z = max(map { $_->{z} } @{$self->{atoms}}) // 0;
        return $max_z;  # assume already in nm
    }
    return 0;
}

# RMS surface roughness (nm)
sub roughness {
    my ($self) = @_;
    return 0 unless $self->{surface};

    my ($nx, $ny) = @{$self->{lattice_size}};
    my $a = $self->{lattice_const} / 10.0;  # Å → nm

    my $sum = 0;
    my $sum2 = 0;
    my $n = $nx * $ny;

    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            my $h = $self->{surface}[$x][$y] * $a;
            $sum  += $h;
            $sum2 += $h * $h;
        }
    }

    my $mean = $sum / $n;
    my $variance = $sum2 / $n - $mean * $mean;
    return sqrt(max($variance, 0));
}

# Film density relative to bulk (fraction, 0–1)
sub density {
    my ($self) = @_;
    return 0 unless $self->{surface} && $self->{lattice};

    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my $max_h = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            $max_h = max($max_h, $self->{surface}[$x][$y]);
        }
    }
    return 0 if $max_h == 0;

    my $occupied = 0;
    my $total = $nx * $ny * $max_h;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            for my $z (0 .. $max_h - 1) {
                $occupied++ if $self->{lattice}[$x][$y][$z];
            }
        }
    }
    return $occupied / $total;
}

# Porosity (1 - density)
sub porosity {
    my ($self) = @_;
    return 1.0 - $self->density;
}

# Composition profile along z (returns array of hashrefs)
sub composition_profile {
    my ($self) = @_;
    return [] unless $self->{lattice} && $self->{species};

    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my %sp_by_id = map { $self->{species}{$_}{id} => $_ } keys %{$self->{species}};
    my @profile;

    for my $z (0 .. $nz-1) {
        my %comp;
        my $total = 0;
        for my $x (0 .. $nx-1) {
            for my $y (0 .. $ny-1) {
                my $id = $self->{lattice}[$x][$y][$z];
                if ($id) {
                    my $name = $sp_by_id{$id} // "species_$id";
                    $comp{$name}++;
                    $total++;
                }
            }
        }
        last if $total == 0;  # above the film
        # Normalize to fractions
        $comp{$_} /= $total for keys %comp;
        push @profile, {
            z_nm => ($z + 0.5) * $self->{lattice_const} / 10.0,
            total_atoms => $total,
            %comp,
        };
    }
    return \@profile;
}

# Export film structure as XYZ format (for visualization in VMD, OVITO, etc.)
sub export_xyz {
    my ($self, $filename) = @_;
    $filename //= 'film.xyz';

    my @atoms;
    if ($self->{lattice}) {
        my ($nx, $ny, $nz) = @{$self->{lattice_size}};
        my %sp_by_id = map { $self->{species}{$_}{id} => $_ } keys %{$self->{species}};
        my $a = $self->{lattice_const};
        for my $x (0 .. $nx-1) {
            for my $y (0 .. $ny-1) {
                for my $z (0 .. $nz-1) {
                    my $id = $self->{lattice}[$x][$y][$z];
                    if ($id) {
                        push @atoms, {
                            species => $sp_by_id{$id} // 'X',
                            x => $x * $a,
                            y => $y * $a,
                            z => $z * $a,
                        };
                    }
                }
            }
        }
    } else {
        @atoms = @{$self->{atoms}};
    }

    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    printf $fh "%d\n", scalar @atoms;
    printf $fh "PVD film export\n";
    for my $a (@atoms) {
        printf $fh "%-4s %12.4f %12.4f %12.4f\n",
               $a->{species}, $a->{x}, $a->{y}, $a->{z};
    }
    close $fh;
    return scalar @atoms;
}

# Export as LAMMPS data file
sub export_lammps_data {
    my ($self, $filename) = @_;
    $filename //= 'film.data';

    my @atoms;
    my %types;
    my $a = $self->{lattice_const};

    if ($self->{lattice}) {
        my ($nx, $ny, $nz) = @{$self->{lattice_size}};
        my %sp_by_id = map { $self->{species}{$_}{id} => $_ } keys %{$self->{species}};
        for my $x (0 .. $nx-1) {
            for my $y (0 .. $ny-1) {
                for my $z (0 .. $nz-1) {
                    my $id = $self->{lattice}[$x][$y][$z];
                    if ($id) {
                        my $sp = $sp_by_id{$id} // "type_$id";
                        $types{$sp} //= scalar(keys %types) + 1;
                        push @atoms, {
                            type => $types{$sp},
                            x => $x * $a, y => $y * $a, z => $z * $a,
                        };
                    }
                }
            }
        }
    } else {
        for my $atom (@{$self->{atoms}}) {
            $types{$atom->{species}} //= scalar(keys %types) + 1;
            push @atoms, {
                type => $types{$atom->{species}},
                x => $atom->{x}, y => $atom->{y}, z => $atom->{z},
            };
        }
    }

    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    printf $fh "LAMMPS data file — Physics::PVD export\n\n";
    printf $fh "%d atoms\n", scalar @atoms;
    printf $fh "%d atom types\n\n", scalar keys %types;
    printf $fh "0.0 %.4f xlo xhi\n", $nx * $a;
    printf $fh "0.0 %.4f ylo yhi\n", $ny * $a;
    printf $fh "0.0 %.4f zlo zhi\n\n", $nz * $a;
    printf $fh "Atoms\n\n";
    my $id = 0;
    for my $atom (@atoms) {
        $id++;
        printf $fh "%d %d %.6f %.6f %.6f\n",
               $id, $atom->{type}, $atom->{x}, $atom->{y}, $atom->{z};
    }
    close $fh;
    return scalar @atoms;
}

# Summary statistics
sub summary {
    my ($self) = @_;
    return {
        thickness_nm => $self->thickness,
        roughness_nm => $self->roughness,
        density      => $self->density,
        porosity     => $self->porosity,
        n_atoms      => $self->{deposited} || scalar(@{$self->{atoms}}),
    };
}

1;

__END__

=head1 NAME

Physics::PVD::Film - Thin film data structure and analysis

=head1 DESCRIPTION

Represents a deposited thin film, either as a 3D lattice occupancy grid
(from KMC simulation) or as an explicit list of atoms. Provides analysis
methods for thickness, roughness, density, composition profiles, porosity,
and export to XYZ and LAMMPS formats.

=cut
