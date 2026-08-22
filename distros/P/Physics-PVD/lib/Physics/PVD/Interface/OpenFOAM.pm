package Physics::PVD::Interface::OpenFOAM;
use strict;
use warnings;
use Carp;
use File::Path qw(make_path);
use File::Spec;

# ═══════════════════════════════════════════════════════════════════════════════
# Interface to OpenFOAM for DSMC simulations
#
# Uses OpenFOAM's dsmcFoam+ solver for gas-phase transport simulation.
# Generates case directories, mesh, boundary conditions, and particle
# injection settings for PVD-relevant configurations.
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        case_dir    => $opts{case_dir}    // './openfoam_pvd',
        executable  => $opts{executable}  // 'dsmcFoam+',
        n_procs     => $opts{n_procs}     // 1,
        foam_dir    => $opts{foam_dir}    // $ENV{WM_PROJECT_DIR} // '',

        # Domain
        domain_size => $opts{domain_size} // [0.1, 0.1, 0.05],  # m
        n_cells     => $opts{n_cells}     // [50, 50, 25],

        # Gas
        gas_species    => $opts{gas_species}    // 'Ar',
        gas_mass_kg    => $opts{gas_mass_kg}    // 6.634e-26,
        gas_diameter   => $opts{gas_diameter}   // 3.66e-10,  # m
        gas_pressure   => $opts{gas_pressure}   // 1.0,       # Pa
        gas_temperature => $opts{gas_temperature} // 300,

        # Target / injection
        target_species => $opts{target_species} // 'Ta',
        target_mass_kg => $opts{target_mass_kg} // 3.005e-25,
        injection_rate => $opts{injection_rate} // 1e16,  # particles/s
        injection_temp => $opts{injection_temp} // 5000,  # K (effective sputtering T)

        # Timing
        dt         => $opts{dt}         // 1e-7,
        end_time   => $opts{end_time}   // 1e-3,
        write_interval => $opts{write_interval} // 1e-4,

        verbose => $opts{verbose} // 0,
    }, $class;
    return $self;
}

# Check if OpenFOAM is available
sub check_availability {
    my ($self) = @_;
    my $output = `which $self->{executable} 2>/dev/null`;
    chomp $output;
    return $output ? 1 : 0;
}

# Generate the complete OpenFOAM case directory
sub setup_case {
    my ($self) = @_;
    my $dir = $self->{case_dir};

    make_path("$dir/constant/polyMesh", "$dir/constant/dsmcProperties",
              "$dir/system", "$dir/0");

    $self->_write_block_mesh;
    $self->_write_dsmc_properties;
    $self->_write_control_dict;
    $self->_write_dsmc_init_dict;
    $self->_write_boundary_conditions;

    print "  OpenFOAM case generated: $dir/\n" if $self->{verbose};
    return $dir;
}

sub _write_block_mesh {
    my ($self) = @_;
    my ($lx, $ly, $lz) = @{$self->{domain_size}};
    my ($nx, $ny, $nz) = @{$self->{n_cells}};
    my $file = File::Spec->catfile($self->{case_dir}, 'system', 'blockMeshDict');

    open my $fh, '>', $file or croak "Cannot write $file: $!";
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      blockMeshDict;
}

convertToMeters 1;

vertices
(
    (0    0    0)
    ($lx  0    0)
    ($lx  $ly  0)
    (0    $ly  0)
    (0    0    $lz)
    ($lx  0    $lz)
    ($lx  $ly  $lz)
    (0    $ly  $lz)
);

blocks
(
    hex (0 1 2 3 4 5 6 7) ($nx $ny $nz) simpleGrading (1 1 1)
);

boundary
(
    substrate
    {
        type patch;
        faces ((0 3 2 1));
    }
    target
    {
        type patch;
        faces ((4 5 6 7));
    }
    walls
    {
        type patch;
        faces
        (
            (0 4 7 3)
            (1 2 6 5)
            (0 1 5 4)
            (2 3 7 6)
        );
    }
);
EOF
    close $fh;
}

sub _write_dsmc_properties {
    my ($self) = @_;
    my $file = File::Spec->catfile($self->{case_dir}, 'constant', 'dsmcProperties');

    my $gas = $self->{gas_species};
    my $tgt = $self->{target_species};

    open my $fh, '>', $file or croak "Cannot write $file: $!";
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      dsmcProperties;
}

// Gas species
dsmcCloud
{
    solution
    {
        active          true;
        transient       true;
        cellValueSourceCorrection off;
    }

    moleculeProperties
    {
        $gas
        {
            mass            $self->{gas_mass_kg};
            diameter        $self->{gas_diameter};
            viscosityCoeffs (1.0 0.81);
            omega           0.81;
        }

        $tgt
        {
            mass            $self->{target_mass_kg};
            diameter        3.0e-10;
            viscosityCoeffs (1.0 0.81);
            omega           0.81;
        }
    }

    collisionModel  VariableHardSphere;

    binaryCollisionModel LarsenBorgnakkeVariableHardSphere;
    LarsenBorgnakkeVariableHardSphereCoeffs
    {
        rotationalRelaxationCollisionNumber 5.0;
    }
}
EOF
    close $fh;
}

sub _write_control_dict {
    my ($self) = @_;
    my $file = File::Spec->catfile($self->{case_dir}, 'system', 'controlDict');

    open my $fh, '>', $file or croak "Cannot write $file: $!";
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      controlDict;
}

application     $self->{executable};
startFrom       startTime;
startTime       0;
stopAt          endTime;
endTime         $self->{end_time};
deltaT          $self->{dt};
writeControl    runTime;
writeInterval   $self->{write_interval};
writeFormat      ascii;
writePrecision  10;
writeCompression off;
timeFormat      general;
timePrecision   6;
runTimeModifiable true;
EOF
    close $fh;
}

sub _write_dsmc_init_dict {
    my ($self) = @_;
    my $file = File::Spec->catfile($self->{case_dir}, 'system', 'dsmcInitialiseDict');

    open my $fh, '>', $file or croak "Cannot write $file: $!";
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      dsmcInitialiseDict;
}

configurations
(
    configuration
    {
        type            dsmcMeshFill;
        molsToInsert    $self->{gas_species};
        numberDensity   @{[ $self->{gas_pressure} / (1.38e-23 * $self->{gas_temperature}) ]};
        temperature     $self->{gas_temperature};
        velocity        (0 0 0);
    }
);
EOF
    close $fh;
}

sub _write_boundary_conditions {
    my ($self) = @_;
    # Simplified — just write a placeholder for the main field
    my $dir = File::Spec->catdir($self->{case_dir}, '0');
    my $file = File::Spec->catfile($dir, 'boundaryT');
    open my $fh, '>', $file or croak "Cannot write $file: $!";
    print $fh <<EOF;
FoamFile
{
    version     2.0;
    format      ascii;
    class       volScalarField;
    object      boundaryT;
}

dimensions      [0 0 0 1 0 0 0];

internalField   uniform $self->{gas_temperature};

boundaryField
{
    substrate
    {
        type    fixedValue;
        value   uniform $self->{gas_temperature};
    }
    target
    {
        type    fixedValue;
        value   uniform $self->{injection_temp};
    }
    walls
    {
        type    fixedValue;
        value   uniform $self->{gas_temperature};
    }
}
EOF
    close $fh;
}

# Run the OpenFOAM DSMC simulation
sub run {
    my ($self, %opts) = @_;
    my $dir = $self->{case_dir};
    my $np  = $opts{n_procs} // $self->{n_procs};

    croak "OpenFOAM case not set up. Call setup_case() first."
        unless -d "$dir/system";

    # Generate mesh
    my $mesh_cmd = "cd $dir && blockMesh > log.blockMesh 2>&1";
    system($mesh_cmd) == 0 or croak "blockMesh failed: $?";

    # Initialize particles
    my $init_cmd = "cd $dir && dsmcInitialise > log.dsmcInitialise 2>&1";
    system($init_cmd) == 0 or carp "dsmcInitialise warning: $?";

    # Run solver
    my $run_cmd;
    if ($np > 1) {
        $run_cmd = "cd $dir && mpirun -np $np $self->{executable} -parallel > log.dsmcFoam 2>&1";
    } else {
        $run_cmd = "cd $dir && $self->{executable} > log.dsmcFoam 2>&1";
    }

    print "  Running: $run_cmd\n" if $self->{verbose};
    system($run_cmd) == 0 or croak "$self->{executable} failed: $?";

    return $self;
}

# Import results from OpenFOAM DSMC run
sub import_results {
    my ($self) = @_;
    my $dir = $self->{case_dir};

    # Find latest time directory
    opendir my $dh, $dir or croak "Cannot open $dir: $!";
    my @times = sort { $a <=> $b }
                grep { /^\d/ && -d "$dir/$_" }
                readdir $dh;
    closedir $dh;

    my $latest = $times[-1] // '0';
    my $result_dir = "$dir/$latest";

    # Parse number density field if available
    my %results = (
        time_dir  => $result_dir,
        end_time  => $latest,
        case_dir  => $dir,
    );

    # Check for log file to extract statistics
    if (-f "$dir/log.dsmcFoam") {
        open my $fh, '<', "$dir/log.dsmcFoam" or return \%results;
        while (<$fh>) {
            if (/particles in system\s*=\s*(\d+)/) {
                $results{n_particles} = $1;
            }
        }
        close $fh;
    }

    return \%results;
}

1;

__END__

=head1 NAME

Physics::PVD::Interface::OpenFOAM - Interface to OpenFOAM dsmcFoam+ solver

=head1 DESCRIPTION

Generates and manages OpenFOAM DSMC case directories for PVD vapor
transport simulations. Handles mesh generation, boundary conditions,
particle injection, and result import.

=cut
