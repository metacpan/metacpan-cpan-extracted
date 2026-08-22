package Physics::Lithography::Interface::LAMMPS;
use strict;
use warnings;
use Carp;
use File::Path qw(make_path);

# ═══════════════════════════════════════════════════════════════════════════════
# LAMMPS interface for ultrafast laser-matter interaction MD simulations
#
# Generates input scripts for:
#   - Two-temperature model (TTM) coupled to MD
#   - Ablation from fs-pulse heating
#   - Phase explosion / spallation
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        output_dir => $opts{output_dir} // './lammps_laser',
        lmp_path   => $opts{lmp_path} // 'lmp',
    }, $class;
    return $self;
}

sub generate_script {
    my ($self, %opts) = @_;
    my $material = $opts{material} // 'gold';
    my $fluence  = $opts{fluence}  // 0.5;        # J/cm²
    my $pulse_fs = $opts{pulse_fs} // 100;        # fs
    my $size_nm  = $opts{size_nm}  // [20, 20, 50];  # x,y,z in nm

    my $dir = $self->{output_dir};
    make_path($dir);

    my $spot_intensity = $fluence * 1e4 / ($pulse_fs * 1e-15);  # W/m²

    my $potential = $self->_get_potential($material);
    my $lattice  = $self->_get_lattice($material);

    open my $fh, '>', "$dir/in.laser" or die "Cannot write $dir/in.laser: $!";
    print $fh <<EOF;
# Ultrafast laser ablation MD simulation
# Material: $material, Fluence: $fluence J/cm², Pulse: ${pulse_fs} fs

units           metal
dimension       3
boundary        p p f
atom_style      atomic

lattice         $lattice->{type} $lattice->{a}
region          box block 0 $size_nm->[0] 0 $size_nm->[1] 0 $size_nm->[2] units box
create_box      1 box
create_atoms    1 box

mass            1 $lattice->{mass}
pair_style      eam
pair_coeff      * * $potential

# Thermostat bulk, free top surface
region          bottom block INF INF INF INF INF 5 units box
group           frozen region bottom

velocity        all create 300 12345 dist gaussian
fix             nve_all all nve
fix             freeze frozen setforce 0 0 0
fix             therm frozen langevin 300 300 0.1 98765

# TTM-like energy deposition via fix heat
# Approximate fluence by applying heat to top layer
region          surface block INF INF INF INF ${\($size_nm->[2]-5)} INF units box
group           heated region surface

variable        t_pulse equal ${\($pulse_fs * 1e-3)}  # ps
variable        E_pulse equal ${\($fluence * $size_nm->[0] * $size_nm->[1] * 1e-16 * 6.242e18)}  # eV
fix             laser heated heat 1 v_E_pulse region surface

timestep        0.001
thermo          100
thermo_style    custom step temp press pe ke etotal

dump            1 all custom 500 $dir/dump.laser.* id type x y z vx vy vz
dump_modify     1 sort id

run             ${\(int($pulse_fs / 1))}
unfix           laser

# Continue for 10 ps after pulse
run             10000

write_data      $dir/final.data
EOF
    close $fh;
    return "$dir/in.laser";
}

sub _get_potential {
    my ($self, $material) = @_;
    my %potentials = (
        gold   => '/usr/share/lammps/potentials/Au_u3.eam',
        copper => '/usr/share/lammps/potentials/Cu_u3.eam',
        aluminum => '/usr/share/lammps/potentials/Al_u3.eam',
    );
    return $potentials{$material} // croak "Unknown material: $material";
}

sub _get_lattice {
    my ($self, $material) = @_;
    my %lattices = (
        gold     => { type => 'fcc', a => 4.08, mass => 196.97 },
        copper   => { type => 'fcc', a => 3.615, mass => 63.546 },
        aluminum => { type => 'fcc', a => 4.05, mass => 26.982 },
    );
    return $lattices{$material} // croak "Unknown material: $material";
}

1;
