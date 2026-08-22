package Physics::CVD::Interface::Cantera;
use strict;
use warnings;
use Carp;
use File::Path qw(make_path);

# ═══════════════════════════════════════════════════════════════════════════════
# Cantera interface for detailed gas-phase and surface chemistry
#
# Generates:
#   - CTI/YAML mechanism files for CVD chemistry
#   - Python scripts for reactor simulations via Cantera
#   - Surface site density and coverage calculations
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        work_dir => $opts{work_dir} // './cantera_cvd',
    }, $class;
    make_path($self->{work_dir}) unless -d $self->{work_dir};
    return $self;
}

# Generate a Cantera YAML mechanism file for TEOS/O₂ → SiO₂
sub generate_sio2_mechanism {
    my ($self, %opts) = @_;
    my $filename = "$self->{work_dir}/sio2_cvd.yaml";

    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    print $fh <<'EOF';
description: |-
  TEOS CVD mechanism for SiO2 deposition
  Simplified mechanism based on Coltrin et al. (1998)

units: {length: cm, quantity: mol, activation-energy: kJ/mol}

phases:
- name: gas
  thermo: ideal-gas
  species: [TEOS, Si(OC2H5)4, Si(OH)4, SiO2_g, O2, H2O, C2H4, CO2, N2]
  kinetics: gas
  reactions: [gas-reactions]
  transport: mixture-averaged

- name: surface
  thermo: ideal-surface
  species: [Si_s, O_s, OH_s, empty_s]
  kinetics: surface
  reactions: [surface-reactions]
  site-density: 1.5e-9  # mol/cm^2

species:
- name: TEOS
  composition: {Si: 1, O: 4, C: 8, H: 20}
  thermo:
    model: constant-cp
    T0: 700 K
    h0: -1300 kJ/mol
    s0: 500 J/mol/K
    cp0: 300 J/mol/K
- name: O2
  composition: {O: 2}
  thermo:
    model: constant-cp
    T0: 700 K
    h0: 0 kJ/mol
    s0: 205 J/mol/K
    cp0: 30 J/mol/K
- name: SiO2_g
  composition: {Si: 1, O: 2}
  thermo:
    model: constant-cp
    T0: 700 K
    h0: -910 kJ/mol
    s0: 228 J/mol/K
    cp0: 44 J/mol/K
- name: H2O
  composition: {H: 2, O: 1}
  thermo:
    model: constant-cp
    T0: 700 K
    h0: -242 kJ/mol
    s0: 189 J/mol/K
    cp0: 34 J/mol/K
- name: N2
  composition: {N: 2}
  thermo:
    model: constant-cp
    T0: 700 K
    h0: 0 kJ/mol
    s0: 192 J/mol/K
    cp0: 29 J/mol/K

gas-reactions:
- equation: TEOS => SiO2_g + 4 C2H4 + 2 H2O
  rate-constant: {A: 1.0e+15, b: 0, Ea: 280 kJ/mol}

surface-reactions:
- equation: TEOS + empty_s => Si_s + 4 C2H4 + 2 H2O
  sticking-coefficient: {A: 0.05, b: 0, Ea: 50 kJ/mol}
- equation: O2 + 2 Si_s => 2 O_s + 2 empty_s
  rate-constant: {A: 1.0e+13, b: 0, Ea: 100 kJ/mol}
EOF
    close $fh;
    return $filename;
}

# Generate a Cantera YAML for Si₃N₄ LPCVD (DCS + NH₃)
sub generate_si3n4_mechanism {
    my ($self, %opts) = @_;
    my $filename = "$self->{work_dir}/si3n4_cvd.yaml";

    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    print $fh <<'EOF';
description: |-
  Si3N4 LPCVD mechanism (DCS + NH3)
  Based on Coltrin & Ho (2000), simplified

units: {length: cm, quantity: mol, activation-energy: kJ/mol}

phases:
- name: gas
  thermo: ideal-gas
  species: [SiH2Cl2, NH3, SiCl2, HCl, H2, N2, SiH2NH]
  kinetics: gas
  reactions: [gas-reactions]

- name: surface
  thermo: ideal-surface
  species: [Si_s, N_s, NH_s, Cl_s, empty_s]
  kinetics: surface
  reactions: [surface-reactions]
  site-density: 1.2e-9

species:
- name: SiH2Cl2
  composition: {Si: 1, H: 2, Cl: 2}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: -320 kJ/mol
    s0: 286 J/mol/K
    cp0: 70 J/mol/K
- name: NH3
  composition: {N: 1, H: 3}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: -46 kJ/mol
    s0: 193 J/mol/K
    cp0: 36 J/mol/K
- name: SiCl2
  composition: {Si: 1, Cl: 2}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: -168 kJ/mol
    s0: 281 J/mol/K
    cp0: 52 J/mol/K
- name: HCl
  composition: {H: 1, Cl: 1}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: -92 kJ/mol
    s0: 187 J/mol/K
    cp0: 29 J/mol/K
- name: H2
  composition: {H: 2}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: 0 kJ/mol
    s0: 131 J/mol/K
    cp0: 29 J/mol/K
- name: N2
  composition: {N: 2}
  thermo:
    model: constant-cp
    T0: 800 K
    h0: 0 kJ/mol
    s0: 192 J/mol/K
    cp0: 29 J/mol/K

gas-reactions:
- equation: SiH2Cl2 => SiCl2 + H2
  rate-constant: {A: 5.0e+13, b: 0, Ea: 240 kJ/mol}
- equation: SiCl2 + NH3 => SiH2NH + 2 HCl
  rate-constant: {A: 1.0e+12, b: 0, Ea: 100 kJ/mol}

surface-reactions:
- equation: SiCl2 + empty_s => Si_s + 2 HCl
  sticking-coefficient: {A: 0.3, b: 0, Ea: 20 kJ/mol}
- equation: NH3 + Si_s => NH_s + 1.5 H2
  sticking-coefficient: {A: 0.1, b: 0, Ea: 30 kJ/mol}
- equation: NH_s + Si_s => N_s + empty_s
  rate-constant: {A: 1.0e+13, b: 0, Ea: 150 kJ/mol}
EOF
    close $fh;
    return $filename;
}

# Generate Python script that uses Cantera to simulate a CVD reactor
sub generate_reactor_script {
    my ($self, %opts) = @_;
    my $mech     = $opts{mechanism} // 'sio2_cvd.yaml';
    my $T        = $opts{temperature} // 700;
    my $P        = $opts{pressure} // 100;
    my $duration = $opts{duration} // 60;

    my $filename = "$self->{work_dir}/run_reactor.py";
    open my $fh, '>', $filename or croak "Cannot write $filename: $!";
    printf $fh <<'EOF', $mech, $T, $P, $duration;
#!/usr/bin/env python3
"""CVD reactor simulation using Cantera — generated by Physics::CVD"""
import cantera as ct
import numpy as np

# Load mechanism
gas = ct.Solution('%s', 'gas')
surf = ct.Interface('%s', 'surface', [gas])

# Set conditions
T = %g  # K
P = %g  # Pa
gas.TPX = T, P, 'TEOS:0.05, O2:0.2, N2:0.75'
surf.TP = T, P

# Create reactor
reactor = ct.IdealGasReactor(gas)
reactor.volume = 1e-3  # m³

# Surface reactor
rsurf = ct.ReactorSurface(surf, reactor, A=0.07)  # 300mm wafer area

# Simulation
sim = ct.ReactorNet([reactor])
duration = %g  # seconds

times = np.linspace(0, duration, 200)
coverages = []
growth_rates = []

for t in times:
    sim.advance(t)
    coverages.append(surf.coverages.copy())
    # Growth rate from surface production rate of SiO2
    growth_rates.append(surf.net_production_rates)

coverages = np.array(coverages)
print(f"Final temperature: {reactor.T:.1f} K")
print(f"Final pressure: {reactor.thermo.P:.1f} Pa")
print(f"Surface coverages: {dict(zip(surf.species_names, surf.coverages))}")
print(f"Simulation complete: {duration}s simulated")
EOF
    close $fh;
    chmod 0755, $filename;
    return $filename;
}

1;
