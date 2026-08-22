package Physics::Electrodeposition;

use strict;
use warnings;
use POSIX qw(floor);

our $VERSION = '1.00';

#-----------------------------------------------------------------------------
# Physical constants (SI / CGS mixed as noted).  Internal length unit is cm,
# concentration is mol/cm^3, current density is A/cm^2, time is s, mass is g.
#-----------------------------------------------------------------------------
use constant {
    FARADAY => 96485.33212,     # C / mol
    R_GAS   => 8.314462618,     # J / (mol K)
};

#=============================================================================
# Constructor
#=============================================================================
# All arguments are named.  Sensible defaults describe an acid copper-sulfate
# damascene bath.  Any parameter may be overridden.
#
#   Metal (cathode deposit) properties
#     metal            name (string)
#     molar_mass       g/mol
#     valence          electrons transferred (n)
#     density          g/cm^3 (deposited solid)
#     E0               standard reduction potential, V vs SHE
#     seed_resistivity Ohm*cm (resistivity of the seed/strike layer material)
#
#   Bath chemistry
#     ion_conc         metal-ion molarity, mol/L        (e.g. Cu2+)
#     acid_conc        supporting acid molarity, mol/L
#     conductivity     electrolyte conductivity, S/cm
#     diffusivity      metal-ion diffusion coeff, cm^2/s
#     temperature      K
#     j0               exchange current density, A/cm^2
#     alpha            cathodic transfer coefficient
#     additive_drop    extra kinetic overpotential from suppressor/leveler, V
#     additive_use     additive consumption, mL per kA*h (per component)
#
#   Tool geometry
#     wafer_diameter   mm
#     electrode_gap    anode-cathode spacing, cm
#     seed_thickness   nm (conductive seed layer on the wafer)
#     boundary_layer   diffusion boundary layer thickness, cm
#     anode_type       'soluble' (dissolving metal) or 'inert' (O2 evolution)
#
#   Photoresist pattern (through-mask plating; optional)
#     gdsii            path to a GDSII layout file, OR
#     pattern          a Physics::Electrodeposition::Pattern object
#     pattern_layer    GDSII layer of the resist openings (undef = all)
#     pattern_datatype optional datatype filter
#     pattern_scope    'die' (stepped reticle) or 'wafer' (full-wafer mask)
#     resist_thickness mask height, um (enables aspect-ratio / fill checks)
#     loading_exponent density-loading coupling for uniformity (0..1, def 0.5)
#
#   Process recipe (give current_density plus ONE of time / target_thickness)
#     current_density  mA/cm^2
#     current_density_basis  'applied' (over wafer) or 'active' (in openings);
#                      defaults to 'active' when a pattern is present
#     time             s
#     target_thickness um  (module solves for the required time)
#     efficiency       cathodic current efficiency (0..1)
#=============================================================================
sub new {
    my ($class, %a) = @_;

    my $self = {
        # ---- metal deposit (copper defaults) ----
        metal            => $a{metal}            // 'Copper',
        molar_mass       => $a{molar_mass}       // 63.546,      # g/mol
        valence          => $a{valence}          // 2,
        density          => $a{density}          // 8.96,        # g/cm^3
        E0               => $a{E0}               // 0.337,       # V vs SHE
        seed_resistivity => $a{seed_resistivity} // 1.90e-6,     # Ohm*cm (thin-film Cu)

        # ---- bath chemistry ----
        ion_conc         => $a{ion_conc}         // 0.28,        # mol/L Cu2+ (~18 g/L)
        acid_conc        => $a{acid_conc}        // 1.8,         # mol/L H2SO4 (~176 g/L)
        conductivity     => $a{conductivity}     // 0.50,        # S/cm
        diffusivity      => $a{diffusivity}      // 7.2e-6,      # cm^2/s (Cu2+)
        temperature      => $a{temperature}      // 298.15,      # K
        j0               => $a{j0}               // 1.0e-3,      # A/cm^2
        alpha            => $a{alpha}            // 0.50,
        additive_drop    => $a{additive_drop}    // 0.20,        # V
        additive_use     => $a{additive_use}     // 5.0,         # mL per kA*h

        # ---- tool geometry ----
        wafer_diameter   => $a{wafer_diameter}   // 300,         # mm
        electrode_gap    => $a{electrode_gap}    // 5.0,         # cm
        seed_thickness   => $a{seed_thickness}   // 60,          # nm
        boundary_layer   => $a{boundary_layer}   // 0.010,       # cm (100 um)
        anode_type       => $a{anode_type}       // 'soluble',

        # ---- photoresist pattern (through-mask plating) ----
        pattern          => $a{pattern},                         # Pattern object
        gdsii            => $a{gdsii},                            # or a GDSII path
        pattern_layer    => $a{pattern_layer},                   # opening layer
        pattern_datatype => $a{pattern_datatype},
        pattern_scope    => $a{pattern_scope}    // 'die',       # 'die' | 'wafer'
        resist_thickness => $a{resist_thickness} // 0,           # um (mask height)
        loading_exponent => $a{loading_exponent} // 0.5,         # density-loading coupling

        # ---- recipe ----
        current_density  => $a{current_density}  // 20,          # mA/cm^2
        current_density_basis => $a{current_density_basis},      # 'applied'|'active'
        time             => $a{time},                            # s (optional)
        target_thickness => $a{target_thickness} // 1.0,         # um (optional)
        efficiency       => $a{efficiency}       // 0.97,        # fraction
    };

    bless $self, $class;

    # Build a pattern from a GDSII path if one was supplied.
    if (!$self->{pattern} && $self->{gdsii}) {
        require Physics::Electrodeposition::Pattern;
        $self->{pattern} = Physics::Electrodeposition::Pattern->new(
            file           => $self->{gdsii},
            layer          => $self->{pattern_layer},
            datatype       => $self->{pattern_datatype},
            scope          => $self->{pattern_scope},
            wafer_diameter => $self->{wafer_diameter},
        );
    }

    # Default current-density basis: feature-referenced when patterned (how a
    # through-mask recipe is normally specified), wafer-referenced otherwise.
    $self->{current_density_basis} //= $self->{pattern} ? 'active' : 'applied';

    return $self;
}

#=============================================================================
# Small accessors / unit helpers
#=============================================================================

# open (plating) area fraction of the wafer field: 1.0 unless a pattern is set.
sub open_fraction {
    my $s = shift;
    return 1.0 unless $s->{pattern};
    my $of = $s->{pattern}->open_fraction;
    return $of > 0 ? $of : 1.0;
}

# Applied (wafer-referenced) current density, A/cm^2 -- drives the TOTAL cell
# current, the seed terminal effect, and the bulk electrolyte IR drop.
sub j_applied {
    my $s = shift;
    my $raw = $s->{current_density} / 1000.0;              # mA/cm^2 -> A/cm^2
    return ($s->{current_density_basis} eq 'active')
         ? $raw * $s->open_fraction                        # active -> wafer
         : $raw;
}

# Active (feature-referenced) current density, A/cm^2 -- the density actually at
# the growing surface inside the resist openings.  Drives Faraday growth,
# transport (j_lim) and kinetic overpotentials.
sub j_active {
    my $s = shift;
    my $raw = $s->{current_density} / 1000.0;
    if ($s->{current_density_basis} eq 'active') { return $raw; }
    my $of = $s->open_fraction;
    return $of > 0 ? $raw / $of : $raw;                    # wafer -> feature
}

# Backward-compatible alias: historically "j" was the wafer-referenced density.
sub j { my $s = shift; return $s->j_applied; }

# convenience accessors in mA/cm^2
sub j_applied_mA { my $s = shift; return $s->j_applied * 1000.0; }
sub j_active_mA  { my $s = shift; return $s->j_active  * 1000.0; }

# wafer (cathode) area, cm^2
sub wafer_area {
    my $s = shift;
    my $r = ($s->{wafer_diameter} / 10.0) / 2.0;   # mm -> cm radius
    return 4 * atan2(1, 1) * $r * $r;              # pi * r^2
}

# wafer radius, cm
sub wafer_radius { my $s = shift; return ($s->{wafer_diameter}/10.0)/2.0; }

# total cell current, A  (driven by the applied, wafer-referenced density)
sub current { my $s = shift; return $s->j_applied * $s->wafer_area; }

# active plating area (inside the resist openings), cm^2
sub active_area { my $s = shift; return $s->open_fraction * $s->wafer_area; }

# metal-ion bulk concentration, mol/cm^3
sub ion_conc_cgs { my $s = shift; return $s->{ion_conc} * 1.0e-3; }

# seed sheet resistance, Ohm/square
sub seed_sheet_resistance {
    my $s = shift;
    my $t_cm = $s->{seed_thickness} * 1.0e-7;      # nm -> cm
    return $s->{seed_resistivity} / $t_cm;
}

#=============================================================================
# Time / thickness coupling (Faraday's law)
#   h = j * t * M * CE / (n * F * rho)          [cm]
#   deposition rate r = dh/dt                    [cm/s]
#   In the openings the film grows at the ACTIVE (feature) current density.
#=============================================================================

# deposition rate in the openings, cm/s
sub deposition_rate {
    my $s = shift;
    return $s->j_active * $s->{molar_mass} * $s->{efficiency}
         / ($s->{valence} * FARADAY * $s->{density});
}

# deposition rate, um/min (convenience)
sub deposition_rate_um_min {
    my $s = shift;
    return $s->deposition_rate * 1.0e4 * 60.0;     # cm/s -> um/min
}

# process time, s.  Uses explicit time if given, else solves from target_thickness.
sub process_time {
    my $s = shift;
    return $s->{time} if defined $s->{time};
    my $h_cm = $s->{target_thickness} * 1.0e-4;    # um -> cm
    my $rate = $s->deposition_rate;                # cm/s
    return $rate > 0 ? $h_cm / $rate : 0;
}

# final film thickness in the openings, cm
sub film_thickness {
    my $s = shift;
    return $s->deposition_rate * $s->process_time;
}

# final film (feature) thickness, um (convenience)
sub film_thickness_um { my $s = shift; return $s->film_thickness * 1.0e4; }

# blanket-equivalent thickness, um: what the SAME total charge would deposit if
# spread over the whole wafer (feature thickness x open fraction).  Highlights
# how through-mask plating concentrates charge into the openings.
sub blanket_equivalent_thickness_um {
    my $s = shift;
    return $s->film_thickness_um * $s->open_fraction;
}

#=============================================================================
# Charge, mass, moles (Faraday's law)
#=============================================================================

# charge passed, C
sub charge { my $s = shift; return $s->current * $s->process_time; }

# moles of metal deposited (accounts for current efficiency)
sub moles_deposited {
    my $s = shift;
    return $s->charge * $s->{efficiency} / ($s->{valence} * FARADAY);
}

# mass of metal deposited, g
sub mass_deposited {
    my $s = shift;
    return $s->moles_deposited * $s->{molar_mass};
}

#=============================================================================
# Mass balance of the chemistry
#   Returns a hash of the moles (and grams where useful) of every species that
#   is consumed or produced over the run.
#=============================================================================
sub mass_balance {
    my $s = shift;
    my $Q  = $s->charge;
    my $n  = $s->{valence};
    my $CE = $s->{efficiency};

    my $mol_metal = $s->moles_deposited;              # metal plated at cathode
    # Side reaction at cathode: hydrogen evolution carries the (1-CE) current.
    #   2 H+ + 2 e- -> H2
    my $mol_H2    = $Q * (1 - $CE) / (2 * FARADAY);
    my $mol_Hplus_cathode = 2 * $mol_H2;              # H+ consumed by HER

    my %mb = (
        charge_C            => $Q,
        metal_mol           => $mol_metal,
        metal_g             => $mol_metal * $s->{molar_mass},
        ion_consumed_mol    => $mol_metal,            # each M(n+) -> M removes one ion
        H2_evolved_mol      => $mol_H2,
        H2_evolved_L_STP    => $mol_H2 * 22.414,      # ideal gas, 0 C 1 atm
        Hplus_consumed_cathode_mol => $mol_Hplus_cathode,
    );

    if ($s->{anode_type} eq 'soluble') {
        # Dissolving metal anode: M -> M(n+) + n e- .  Assume ~100% anode eff.
        # Ideally replenishes the ion the cathode removed (closed loop).
        $mb{anode_metal_dissolved_mol} = $Q / ($n * FARADAY);
        $mb{ion_replenished_mol}       = $mb{anode_metal_dissolved_mol};
        $mb{net_ion_change_mol}        = $mb{ion_replenished_mol} - $mb{ion_consumed_mol};
        $mb{O2_evolved_mol}            = 0;
        $mb{Hplus_generated_anode_mol} = 0;
    } else {
        # Inert anode: 2 H2O -> O2 + 4 H+ + 4 e-
        $mb{anode_metal_dissolved_mol} = 0;
        $mb{ion_replenished_mol}       = 0;
        $mb{net_ion_change_mol}        = -$mb{ion_consumed_mol};   # bath depletes
        $mb{O2_evolved_mol}            = $Q / (4 * FARADAY);
        $mb{O2_evolved_L_STP}          = $mb{O2_evolved_mol} * 22.414;
        $mb{Hplus_generated_anode_mol} = $Q / FARADAY;            # 4H+/4e- = 1 H+ per e-
    }

    # Net acid (H+) change = generated at anode - consumed by HER at cathode
    $mb{net_Hplus_change_mol} =
        ($mb{Hplus_generated_anode_mol} // 0) - $mol_Hplus_cathode;

    # Additive consumption (organic accelerator/suppressor/leveler), mL.
    #   dosed per amp-hour of charge.
    my $Ah = $Q / 3600.0;
    $mb{amp_hours}          = $Ah;
    $mb{additive_mL}        = $s->{additive_use} * ($Ah / 1000.0); # per kA*h

    return \%mb;
}

#=============================================================================
# Transport limits and current efficiency check
#   Diffusion-limited current density  j_lim = n F D C_b / delta
#=============================================================================
sub limiting_current_density {
    my $s = shift;
    return $s->{valence} * FARADAY * $s->{diffusivity}
         * $s->ion_conc_cgs / $s->{boundary_layer};       # A/cm^2
}

# fraction of the limiting current the openings use (0..1). Should be < ~0.7.
# Uses the ACTIVE (feature) current density, which is what the surface sees.
sub current_fraction_of_limit {
    my $s = shift;
    my $jl = $s->limiting_current_density;
    return $jl > 0 ? $s->j_active / $jl : 0;
}

#=============================================================================
# Cell voltage and power
#   V_cell = E_thermo + |eta_act,c| + |eta_act,a| + |eta_conc|
#          + I*R_solution + additive_drop
#=============================================================================

# thermodynamic cell potential, V
sub thermodynamic_voltage {
    my $s = shift;
    # Soluble (symmetric M/M(n+)) cell: cathode and anode couples cancel -> ~0.
    # Inert anode: O2/H2O (1.23 V) vs M(n+)/M couple.
    return $s->{anode_type} eq 'soluble' ? 0.0 : (1.229 - $s->{E0});
}

# cathodic activation overpotential (Tafel), V (magnitude).  The interfacial
# kinetics respond to the ACTIVE (feature) current density.
sub activation_overpotential {
    my $s = shift;
    my $j = $s->j_active;
    return 0 if $j <= 0 || $s->{j0} <= 0;
    my $slope = R_GAS * $s->{temperature}
              / ($s->{alpha} * $s->{valence} * FARADAY);   # V (natural-log form)
    my $eta = $slope * log($j / $s->{j0});
    return $eta > 0 ? $eta : 0;
}

# concentration overpotential, V (magnitude)
sub concentration_overpotential {
    my $s = shift;
    my $ratio = $s->current_fraction_of_limit;
    $ratio = 0.999 if $ratio >= 1;                          # guard log domain
    my $pre = R_GAS * $s->{temperature} / ($s->{valence} * FARADAY);
    return abs($pre * log(1 - $ratio));
}

# ohmic (IR) drop through the electrolyte, V.  The bulk field is set by the
# APPLIED (wafer-referenced) current density spread over the anode-cathode gap.
sub ohmic_drop {
    my $s = shift;
    # E = j * gap / kappa   (equivalently I*R with R = gap/(kappa*A))
    return $s->j_applied * $s->{electrode_gap} / $s->{conductivity};
}

# total cell voltage, V
sub cell_voltage {
    my $s = shift;
    my $anode_act = $s->{anode_type} eq 'soluble'
        ? $s->activation_overpotential          # symmetric: similar anodic term
        : 0.5;                                   # O2 evolution has large overpotential
    return $s->thermodynamic_voltage
         + $s->activation_overpotential
         + $anode_act
         + $s->concentration_overpotential
         + $s->ohmic_drop
         + $s->{additive_drop};
}

# electrical power delivered to the cell, W
sub power { my $s = shift; return $s->cell_voltage * $s->current; }

# total electrical energy, J
sub energy { my $s = shift; return $s->power * $s->process_time; }

# energy per wafer, J (same as energy for single-wafer tool) and Wh
sub energy_Wh { my $s = shift; return $s->energy / 3600.0; }

# specific energy, kWh per kg of metal
sub specific_energy_kWh_kg {
    my $s = shift;
    my $kg = $s->mass_deposited / 1000.0;
    return $kg > 0 ? ($s->energy / 3.6e6) / $kg : 0;
}

#=============================================================================
# Uniformity and smoothness
#=============================================================================

# Polarization (charge-transfer) areal resistance, Ohm*cm^2:  d(eta_act)/dj
sub polarization_resistance {
    my $s = shift;
    my $j = $s->j_active;
    my $slope = R_GAS * $s->{temperature}
              / ($s->{alpha} * $s->{valence} * FARADAY);    # V (per ln)
    return $j > 0 ? $slope / $j : 0;                        # Ohm*cm^2
}

# Concentration polarization areal resistance, Ohm*cm^2:  d(eta_conc)/dj
sub concentration_resistance {
    my $s = shift;
    my $jl = $s->limiting_current_density;
    my $j  = $s->j_active;
    return 0 if $jl <= 0 || $j >= $jl;
    my $pre = R_GAS * $s->{temperature} / ($s->{valence} * FARADAY);
    return $pre / ($jl - $j);                               # Ohm*cm^2
}

# Electrolyte areal resistance seen normal to the wafer, Ohm*cm^2 = gap/kappa
sub electrolyte_areal_resistance {
    my $s = shift;
    return $s->{electrode_gap} / $s->{conductivity};
}

# Total series areal resistance the interface presents, Ohm*cm^2.  This is what
# the lateral seed drop must compete against to redistribute current.
sub series_areal_resistance {
    my $s = shift;
    return $s->polarization_resistance
         + $s->concentration_resistance
         + $s->electrolyte_areal_resistance;
}

# Wagner number Wa = kappa * (d eta / d j) / L.  Large Wa -> uniform (kinetics
# control).  Small Wa -> ohmic/primary distribution controls (tool field shaping
# needed).  L is the macroscopic length (wafer radius) for cross-wafer throwing.
sub wagner_number {
    my $s = shift;
    my $L = $s->wafer_radius;                               # characteristic length, cm
    return $L > 0 ? $s->{conductivity} * $s->polarization_resistance / $L : 0;
}

# Terminal effect: radial center-to-edge potential drop in the resistive seed
# for uniform current collection over a disk:  dV = j * Rs * R^2 / 4  [V].
# The seed carries the TOTAL current, so this uses the applied density.
sub terminal_effect_drop {
    my $s = shift;
    my $Rs = $s->seed_sheet_resistance;
    my $R  = $s->wafer_radius;
    return $s->j_applied * $Rs * $R * $R / 4.0;
}

# Dimensionless terminal-effect severity (the "drive" for edge-fast plating):
# the lateral seed drop relative to the wafer-normal voltage (j * R_series) that
# would have to be overcome to keep current uniform.  <<1 = negligible.
sub terminal_effect_ratio {
    my $s = shift;
    my $vnorm = $s->j_applied * $s->series_areal_resistance;
    return $vnorm > 0 ? $s->terminal_effect_drop / $vnorm : 0;
}

# Estimated within-wafer non-uniformity (WIWNU) as a percentage (1-sigma),
# driven by the terminal effect and bounded by a saturating response (the
# feedback of film thickening and finite cell voltage limits runaway).  This is
# the *uncompensated* tendency, before tool countermeasures (thief, shields,
# high-resistance chemistry, cold-entry current ramp).
sub nonuniformity_percent {
    my $s = shift;
    my $drive = $s->terminal_effect_ratio;
    my $frac  = 0.5 * $drive / (1 + $drive);   # saturates toward 0.5
    return 100.0 * $frac;
}

# Surface roughness / smoothness estimate.
#   RMS roughness grows with film thickness, with the driving ratio j/j_lim,
#   and is suppressed by leveling additives.  Engineering estimate, returns nm.
sub roughness_nm {
    my $s = shift;
    my $h_nm  = $s->film_thickness_um * 1000.0;
    my $ratio = $s->current_fraction_of_limit;
    # additive leveling factor: strong suppressor/leveler -> low factor.
    my $lev = $s->{additive_drop} > 0 ? 0.15 : 1.0;
    # roughness ~ leveling * sqrt(h) * (ratio growth term)
    my $rough = $lev * sqrt($h_nm) * (0.3 + 1.7 * $ratio * $ratio);
    return $rough;
}

# Qualitative smoothness verdict
sub smoothness_verdict {
    my $s = shift;
    my $ratio = $s->current_fraction_of_limit;
    if    ($ratio > 0.9) { return 'ROUGH / powdery risk (near mass-transport limit)'; }
    elsif ($ratio > 0.7) { return 'MARGINAL (approaching limiting current)'; }
    elsif ($ratio > 0.4) { return 'GOOD (well below limiting current)'; }
    else                 { return 'EXCELLENT (kinetically controlled, bright)'; }
}

#=============================================================================
# Pattern (photoresist / through-mask) helpers
#=============================================================================

# is a GDSII/pattern loaded?
sub has_pattern { return defined $_[0]->{pattern}; }

# within-die loading (pattern-density) non-uniformity, %
sub loading_nonuniformity {
    my $s = shift;
    return 0 unless $s->{pattern};
    return $s->{pattern}->loading_nonuniformity($s->{loading_exponent});
}

# isolated/dense plated-thickness ratio from the loading effect
sub isolated_to_dense_ratio {
    my $s = shift;
    return 1 unless $s->{pattern};
    return $s->{pattern}->isolated_to_dense_ratio($s->{loading_exponent});
}

# within-wafer non-uniformity from radial density variation (wafer-scope), %
sub pattern_radial_nonuniformity {
    my $s = shift;
    return 0 unless $s->{pattern} && $s->{pattern_scope} eq 'wafer';
    return $s->{pattern}->radial_nonuniformity($s->{loading_exponent});
}

# feature aspect ratio = resist thickness / CD (0 if resist height unknown)
sub feature_aspect_ratio {
    my $s = shift;
    return 0 unless $s->{pattern} && $s->{resist_thickness} > 0;
    my ($cd_min) = $s->{pattern}->cd_stats;                 # smallest CD, um
    return $cd_min > 0 ? $s->{resist_thickness} / $cd_min : 0;
}

# void / fill-risk caution for high-aspect openings near the transport limit
sub fill_risk_verdict {
    my $s = shift;
    return 'n/a (blanket, no pattern)' unless $s->{pattern};
    my $ar    = $s->feature_aspect_ratio;
    my $ratio = $s->current_fraction_of_limit;
    if ($ar >= 3 && $ratio > 0.5) {
        return 'HIGH void risk (deep openings + near transport limit): lower j / boost additives';
    } elsif ($ar >= 3) {
        return 'MODERATE (deep openings): keep j low, ensure additive throwing power';
    } elsif ($ratio > 0.8) {
        return 'MODERATE (near transport limit): improve agitation into openings';
    }
    return 'LOW (openings fill conformally at these conditions)';
}

#=============================================================================
# Formatted report
#=============================================================================
sub report {
    my $s = shift;
    my $mb = $s->mass_balance;

    my $t   = $s->process_time;
    my $out = '';
    my $line = ('=' x 74) . "\n";
    my $sub  = ('-' x 74) . "\n";

    $out .= $line;
    $out .= sprintf "  ELECTRODEPOSITION MODEL REPORT : %s on %d mm wafer\n",
                    $s->{metal}, $s->{wafer_diameter};
    $out .= $line;

    #--- process conditions ---
    $out .= "PROCESS CONDITIONS\n$sub";
    $out .= sprintf "  Wafer diameter .............. %8.1f mm  (area %.1f cm^2)\n",
                    $s->{wafer_diameter}, $s->wafer_area;
    if ($s->has_pattern) {
        $out .= sprintf "  Current density ............. applied %.2f / active %.2f mA/cm^2\n",
                        $s->j_applied_mA, $s->j_active_mA;
    } else {
        $out .= sprintf "  Current density ............. %8.2f mA/cm^2\n", $s->{current_density};
    }
    $out .= sprintf "  Cell current ................ %8.2f A\n", $s->current;
    $out .= sprintf "  Current efficiency .......... %8.1f %%\n", $s->{efficiency}*100;
    $out .= sprintf "  Anode type .................. %8s\n", $s->{anode_type};
    $out .= sprintf "  Bath: [ion]=%.2f M, [acid]=%.2f M, T=%.1f C, kappa=%.2f S/cm\n",
                    $s->{ion_conc}, $s->{acid_conc}, $s->{temperature}-273.15, $s->{conductivity};
    $out .= sprintf "  Plating time ................ %8.1f s  (%.2f min)\n", $t, $t/60;

    #--- photoresist pattern (through-mask plating) ---
    if ($s->has_pattern) {
        my $p = $s->{pattern};
        my ($cdmin, $cdmean, $cdmax) = $p->cd_stats;
        $out .= "\nPHOTORESIST PATTERN (GDSII)\n$sub";
        $out .= sprintf "  Source ...................... %s (layer %s, scope %s)\n",
                        $s->{gdsii} // 'pattern object',
                        defined $s->{pattern_layer} ? $s->{pattern_layer} : 'all',
                        $s->{pattern_scope};
        $out .= sprintf "  Openings (features) ......... %d\n", $p->feature_count;
        $out .= sprintf "  Feature CD (min/mean/max) ... %.2f / %.2f / %.2f um\n",
                        $cdmin, $cdmean, $cdmax;
        $out .= sprintf "  Open (plating) area ......... %.3f mm^2 of %.3f mm^2 field\n",
                        $p->open_area_um2/1e6, $p->field_area_um2/1e6;
        $out .= sprintf "  Pattern density (open frac) . %8.3f  (%.1f%% open)\n",
                        $s->open_fraction, $s->open_fraction*100;
        $out .= sprintf "  Active plating area ......... %8.2f cm^2 of %.1f cm^2 wafer\n",
                        $s->active_area, $s->wafer_area;
        $out .= sprintf "  Charge concentration ........ %8.2fx (feature vs blanket)\n",
                        $s->open_fraction > 0 ? 1/$s->open_fraction : 1;
        if ($s->{resist_thickness} > 0) {
            $out .= sprintf "  Resist height / aspect ratio  %.2f um  /  AR %.2f\n",
                            $s->{resist_thickness}, $s->feature_aspect_ratio;
        }
    }

    #--- film thickness ---
    $out .= "\nFILM THICKNESS\n$sub";
    $out .= sprintf "  Deposition rate ............. %8.3f um/min%s\n",
                    $s->deposition_rate_um_min,
                    $s->has_pattern ? '  (in openings)' : '';
    $out .= sprintf "  FINAL FILM THICKNESS ........ %8.3f um  (%.1f nm)%s\n",
                    $s->film_thickness_um, $s->film_thickness_um*1000,
                    $s->has_pattern ? '  in features' : '';
    if ($s->has_pattern) {
        $out .= sprintf "  Blanket-equivalent thickness  %8.3f um  (same charge, unpatterned)\n",
                        $s->blanket_equivalent_thickness_um;
    }

    #--- mass balance ---
    $out .= "\nMASS BALANCE (chemistry)\n$sub";
    $out .= sprintf "  Charge passed ............... %10.1f C  (%.3f A*h)\n",
                    $mb->{charge_C}, $mb->{amp_hours};
    $out .= sprintf "  %s deposited (cathode) ...... %10.4f g  (%.5f mol)\n",
                    $s->{metal}, $mb->{metal_g}, $mb->{metal_mol};
    $out .= sprintf "  Cathode:  M(n+) + %d e- -> M   consumes %.5f mol ion\n",
                    $s->{valence}, $mb->{ion_consumed_mol};
    if ($s->{anode_type} eq 'soluble') {
        $out .= sprintf "  Anode:    M -> M(n+) + %d e-   supplies %.5f mol ion\n",
                        $s->{valence}, $mb->{ion_replenished_mol};
        $out .= sprintf "  Net bath ion change ......... %+.6f mol  (closed loop)\n",
                        $mb->{net_ion_change_mol};
    } else {
        $out .= sprintf "  Anode:    2 H2O -> O2 + 4 H+ + 4 e-\n";
        $out .= sprintf "  O2 evolved (anode) .......... %.5f mol  (%.3f L STP)\n",
                        $mb->{O2_evolved_mol}, $mb->{O2_evolved_L_STP};
        $out .= sprintf "  H+ generated (anode) ........ %.5f mol\n", $mb->{Hplus_generated_anode_mol};
        $out .= sprintf "  Net bath ion change ......... %+.6f mol  (must be dosed)\n",
                        $mb->{net_ion_change_mol};
    }
    $out .= sprintf "  H2 side rxn (cathode) ....... %.6f mol  (%.4f L STP) @ CE=%.0f%%\n",
                    $mb->{H2_evolved_mol}, $mb->{H2_evolved_L_STP}, $s->{efficiency}*100;
    $out .= sprintf "  Net acid (H+) change ........ %+.6f mol\n", $mb->{net_Hplus_change_mol};
    $out .= sprintf "  Organic additive consumed ... %.4f mL  (@ %.1f mL/kA*h)\n",
                    $mb->{additive_mL}, $s->{additive_use};

    #--- power ---
    $out .= "\nPOWER INPUT\n$sub";
    $out .= sprintf "  Thermodynamic voltage ....... %8.3f V\n", $s->thermodynamic_voltage;
    $out .= sprintf "  Activation overpotential .... %8.3f V (cathode)\n", $s->activation_overpotential;
    $out .= sprintf "  Concentration overpotential . %8.3f V\n", $s->concentration_overpotential;
    $out .= sprintf "  IR (ohmic) drop ............. %8.3f V\n", $s->ohmic_drop;
    $out .= sprintf "  Additive kinetic drop ....... %8.3f V\n", $s->{additive_drop};
    $out .= sprintf "  TOTAL CELL VOLTAGE .......... %8.3f V\n", $s->cell_voltage;
    $out .= sprintf "  POWER INPUT ................. %8.2f W\n", $s->power;
    $out .= sprintf "  Energy for run .............. %8.2f J  (%.4f Wh)\n", $s->energy, $s->energy_Wh;
    $out .= sprintf "  Specific energy ............. %8.2f kWh/kg %s\n",
                    $s->specific_energy_kWh_kg, $s->{metal};

    #--- uniformity & smoothness ---
    $out .= "\nUNIFORMITY & SMOOTHNESS\n$sub";
    $out .= sprintf "  Limiting current density .... %8.2f mA/cm^2\n",
                    $s->limiting_current_density*1000;
    $out .= sprintf "  Operating / limiting ratio .. %8.2f  (%.0f%% of j_lim)\n",
                    $s->current_fraction_of_limit, $s->current_fraction_of_limit*100;
    $out .= sprintf "  Wagner number (throwing pwr). %8.2f  (>>1 = uniform)\n", $s->wagner_number;
    $out .= sprintf "  Seed sheet resistance ....... %8.3f Ohm/sq  (%d nm seed)\n",
                    $s->seed_sheet_resistance, $s->{seed_thickness};
    $out .= sprintf "  Terminal-effect drop ........ %8.3f V  (center-to-edge in seed)\n",
                    $s->terminal_effect_drop;
    $out .= sprintf "  Terminal-effect severity .... %8.2f  (<<1 = negligible)\n",
                    $s->terminal_effect_ratio;
    $out .= sprintf "  Est. within-wafer non-unif .. %8.2f %% (1-sigma, uncompensated)\n",
                    $s->nonuniformity_percent;
    $out .= sprintf "  Est. RMS roughness .......... %8.2f nm\n", $s->roughness_nm;
    $out .= sprintf "  Smoothness verdict .......... %s\n", $s->smoothness_verdict;
    if ($s->has_pattern) {
        $out .= sprintf "  Loading (pattern) WIDNU ..... %8.2f %% (dense vs isolated)\n",
                        $s->loading_nonuniformity;
        $out .= sprintf "  Isolated/dense height ratio . %8.2fx (isolated features taller)\n",
                        $s->isolated_to_dense_ratio;
        if ($s->{pattern_scope} eq 'wafer') {
            $out .= sprintf "  Radial (within-wafer) NU .... %8.2f %% (center-to-edge density)\n",
                            $s->pattern_radial_nonuniformity;
        }
        $out .= sprintf "  Feature fill risk ........... %s\n", $s->fill_risk_verdict;
    }

    $out .= "\n" . $line;
    $out .= $s->_insight_text;
    $out .= $line;
    return $out;
}

# Narrative engineering insight tailored to the computed numbers.
sub _insight_text {
    my $s = shift;
    my @notes;

    my $ratio = $s->current_fraction_of_limit;
    my $wa    = $s->wagner_number;
    my $te    = $s->terminal_effect_ratio;
    my $nu    = $s->nonuniformity_percent;

    push @notes, "INSIGHT";
    push @notes, ('-' x 74);

    # pattern / through-mask note (first, when present)
    if ($s->has_pattern) {
        push @notes, sprintf(
          "* Photoresist pattern: only %.1f%% of the field is open, so the applied\n"
        . "  %.1f mA/cm^2 concentrates to %.1f mA/cm^2 in the openings (%.1fx). Same\n"
        . "  charge builds features %.1fx thicker than an equivalent blanket film.",
          $s->open_fraction*100, $s->j_applied_mA, $s->j_active_mA,
          $s->open_fraction>0 ? 1/$s->open_fraction : 1,
          $s->open_fraction>0 ? 1/$s->open_fraction : 1);
        push @notes, sprintf(
          "* Loading effect: pattern-density variation gives ~%.1f%% within-die\n"
        . "  thickness spread; isolated openings plate ~%.2fx taller than dense\n"
        . "  arrays. Flatten with a leveler, a resistive bath, or layout dummy fill.",
          $s->loading_nonuniformity, $s->isolated_to_dense_ratio);
        if ($s->{resist_thickness} > 0 && $s->feature_aspect_ratio >= 3) {
            push @notes, sprintf(
              "* High aspect ratio (%.1f): keep active j well below j_lim and rely on\n"
            . "  accelerator/suppressor throwing power to avoid seams/voids.",
              $s->feature_aspect_ratio);
        }
    }

    # transport / smoothness
    if ($ratio < 0.5) {
        push @notes, sprintf(
          "* Smoothness: operating at %.0f%% of the diffusion limit keeps growth\n"
        . "  charge-transfer controlled -> dense, level, bright film. The %.2f M\n"
        . "  ion supply is not starving the surface (est. RMS ~ %.1f nm).",
          $ratio*100, $s->{ion_conc}, $s->roughness_nm);
    } elsif ($ratio < 0.8) {
        push @notes, sprintf(
          "* Smoothness: %.0f%% of the diffusion limit is workable but leaves less\n"
        . "  margin; RMS ~ %.1f nm. Consider more flow (thinner boundary layer).",
          $ratio*100, $s->roughness_nm);
    } else {
        push @notes, sprintf(
          "* Smoothness RISK: %.0f%% of the diffusion limit invites rough, nodular\n"
        . "  or powdery growth (RMS ~ %.1f nm). Raise agitation / flow (thinner\n"
        . "  boundary layer) or lower j to recover a bright, level deposit.",
          $ratio*100, $s->roughness_nm);
    }

    # uniformity / terminal effect / wafer size
    push @notes, sprintf(
      "* Wafer size drives the terminal effect: over the %.0f cm radius the seed\n"
    . "  collects current laterally, giving a %.0f mV center-to-edge drop in the\n"
    . "  %d nm seed. Drive vs wafer-normal voltage = %.2f.",
      $s->wafer_radius, $s->terminal_effect_drop*1000, $s->{seed_thickness}, $te);

    if ($te > 0.5) {
        push @notes, sprintf(
          "  -> STRONG edge-fast tendency (~%.0f%% uncompensated WIWNU). Real 300 mm\n"
        . "     tools counter this with: thicker/lower-Rs seed, HIGH-resistance\n"
        . "     (high throwing-power) chemistry, a peripheral thief/edge ring, and\n"
        . "     a low 'cold-entry' current ramp while the film is still thin.", $nu);
    } elsif ($te > 0.2) {
        push @notes, sprintf(
          "  -> Moderate edge-fast tendency (~%.0f%% uncompensated WIWNU); a thief\n"
        . "     ring or mild current ramp should bring it in spec.", $nu);
    } else {
        push @notes, sprintf(
          "  -> Terminal effect well controlled (~%.0f%% WIWNU) for this seed and\n"
        . "     chemistry.", $nu);
    }

    # Wagner number interpretation (adaptive to magnitude)
    if ($wa >= 1) {
        push @notes, sprintf(
          "* Wagner number = %.2f (>=1): charge-transfer resistance dominates the\n"
        . "  electrolyte resistance across the wafer, so the PRIMARY current is\n"
        . "  thrown out evenly by the kinetics; additives fine-tune the rest.", $wa);
    } else {
        push @notes, sprintf(
          "* Wagner number = %.2f (<1): the macroscopic distribution is OHMIC\n"
        . "  (primary) controlled, so cross-wafer uniformity relies on tool field\n"
        . "  shaping (anode shields, segmented/virtual anode, flow baffles) rather\n"
        . "  than on chemistry alone. The additive package still levels features.", $wa);
    }

    # power / geometry note
    push @notes, sprintf(
      "* Power/geometry: the %.1f cm gap at kappa=%.2f S/cm sets a %.0f mV IR drop,\n"
    . "  the largest term in the %.2f V cell (%.1f W). A closer, well-baffled gap\n"
    . "  with uniform flow lowers energy and evens the field.",
      $s->{electrode_gap}, $s->{conductivity}, $s->ohmic_drop*1000,
      $s->cell_voltage, $s->power);

    return join("\n", @notes) . "\n";
}

1;

__END__

=head1 NAME

Physics::Electrodeposition - Model metal electrodeposition (electroplating) on
semiconductor wafers.

=head1 SYNOPSIS

    use Physics::Electrodeposition;

    my $ecd = Physics::Electrodeposition->new(
        metal            => 'Copper',
        wafer_diameter   => 300,      # mm
        current_density  => 20,       # mA/cm^2
        target_thickness => 1.0,      # um  (module solves for time)
        efficiency       => 0.97,
        anode_type       => 'soluble',
    );

    print $ecd->report;               # full text report

    my $h  = $ecd->film_thickness_um; # final thickness, um
    my $P  = $ecd->power;             # cell power, W
    my $mb = $ecd->mass_balance;      # hashref of species moles/grams

=head1 DESCRIPTION

Physics::Electrodeposition implements a first-principles engineering model of
constant-current (galvanostatic) electrodeposition of a metal onto a circular
wafer cathode. It is parameterized for an acid copper-sulfate damascene bath by
default but works for any metal/bath by overriding constructor arguments.

The model couples Faraday's law (mass and thickness), a lumped cell-voltage
model (thermodynamic + activation + concentration overpotentials + ohmic drop +
additive drop) for power, a diffusion-limited current density for transport, and
geometry-based estimates of uniformity (Wagner number, seed terminal effect) and
surface smoothness.

=head1 KEY METHODS

=over 4

=item new(%args)

Construct a model. See the source header for the full list of named parameters
and their default (copper) values.

=item film_thickness_um / deposition_rate_um_min / process_time

Growth results from Faraday's law.

=item mass_deposited / moles_deposited / charge / mass_balance

Chemistry mass balance, including anode reaction, hydrogen side reaction, acid
balance, gas evolution, and additive consumption.

=item cell_voltage / power / energy / specific_energy_kWh_kg

Electrical power model.

=item limiting_current_density / current_fraction_of_limit / wagner_number /
terminal_effect_drop / nonuniformity_percent / roughness_nm / smoothness_verdict

Transport, uniformity and smoothness metrics.

=item open_fraction / j_applied / j_active / active_area /
blanket_equivalent_thickness_um

Through-mask patterning: the open-area fraction from the GDSII mask, the applied
(wafer-referenced) and active (in-opening) current densities, the plated area,
and the blanket-equivalent thickness for the same charge.

=item loading_nonuniformity / isolated_to_dense_ratio / feature_aspect_ratio /
fill_risk_verdict

Pattern-density (loading) effect on thickness uniformity and feature fill risk.

=item report

Return a formatted multi-section text report with narrative insight (adds a
PHOTORESIST PATTERN section when a GDSII mask is supplied).

=back

=head1 PHOTORESIST PATTERNING (GDSII)

Pass C<< gdsii => 'mask.gds' >> (and usually C<pattern_layer>) to model
through-mask plating. The metal then grows only in the resist openings, so the
in-opening (active) current density is the applied density divided by the open
fraction, features grow C<1/open_fraction> thicker than a blanket film for the
same charge, and pattern-density variation drives a loading (isolated-vs-dense)
non-uniformity. See L<Physics::Electrodeposition::GDSII> and
L<Physics::Electrodeposition::Pattern>.

=head1 UNITS

Public convenience methods report engineering units (um, mA/cm^2, V, W). Internal
calculations use cm, A/cm^2, mol/cm^3, s and g.

=head1 CAVEATS

The uniformity, roughness, loading and additive-consumption figures are
calibrated engineering estimates, not a full 3-D primary/secondary/tertiary
current distribution simulation. Use them for scoping and sensitivity studies.

=head1 AUTHOR

Generated for the Physics-Electrodeposition project.

=cut
