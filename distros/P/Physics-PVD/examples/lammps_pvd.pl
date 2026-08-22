#!/usr/bin/perl
# Example: LAMMPS-based PVD deposition of Cu on Ta substrate
use strict;
use warnings;
use lib '../lib';
use Physics::PVD;

my $pvd = Physics::PVD->new(temperature => 300, verbose => 1);

# Get the LAMMPS interface
my $lmp = $pvd->interface('lammps',
    executable   => 'lmp',
    work_dir     => './lammps_cu_on_ta',
    n_procs      => 4,

    # Substrate
    substrate_material => 'Ta',
    substrate_size     => [8, 8, 6],     # unit cells
    substrate_orient   => [1, 1, 0],

    # Depositing species
    deposit_species => 'Cu',
    deposit_energy  => 3.0,    # eV kinetic energy at arrival
    deposit_rate    => 1,
    deposit_interval => 2000,  # timesteps between deposits

    # Potential
    potential_type => 'eam/alloy',
    potential_file => 'potentials/CuTa.eam.alloy',

    # MD settings
    timestep    => 1.0,        # fs
    temperature => 300,        # K
);

# Check if LAMMPS is available
if ($lmp->check_availability) {
    print "LAMMPS found. Generating input files...\n";

    # Generate deposition script
    my $input_file = $lmp->generate_input(
        template => 'deposition',
        params   => {
            n_deposits  => 50,
            run_between => 2000,
            total_steps => 100000,
        },
    );
    printf "  Input script: %s\n", $input_file;

    # Generate sputtering cascade study
    my $sputter_file = $lmp->generate_input(
        template => 'sputtering',
        filename => './lammps_cu_on_ta/in.sputter',
        params   => {
            ion_energy  => 300,   # eV Ar ion
            total_steps => 5000,
        },
    );
    printf "  Sputtering script: %s\n", $sputter_file;

    # Run deposition (uncomment when potential file is available)
    # $lmp->run(input_file => $input_file);
    # my $thermo = $lmp->parse_log;
    # my $frames = $lmp->parse_dump;

    print "\n  Scripts generated. To run:\n";
    print "    cd lammps_cu_on_ta && lmp -in in.pvd\n";
} else {
    print "LAMMPS not found in PATH.\n";
    print "Install LAMMPS: https://docs.lammps.org/Install.html\n";
    print "Generating input scripts anyway for inspection...\n";

    my $input_file = $lmp->generate_input(
        template => 'deposition',
        params   => { n_deposits => 50 },
    );
    printf "  Generated: %s\n", $input_file;
}
