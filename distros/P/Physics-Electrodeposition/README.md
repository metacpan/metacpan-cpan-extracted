# Physics::Electrodeposition

A Perl module for **modeling electrodeposition (electroplating) of metals onto
semiconductor wafers**. It couples Faraday's law, a lumped electrochemical
cell‑voltage model, mass‑transport limits, and geometry‑based current‑distribution
physics to predict:

- **Film thickness** and deposition rate
- A full **mass balance** of the chemistry (ion consumption, anode reaction,
  hydrogen side reaction, acid balance, gas evolution, additive consumption)
- **Power input** (cell voltage breakdown, power, energy, specific energy)
- **Uniformity and smoothness** insight from tool geometry, wafer size, chemistry
  and process conditions (limiting current, Wagner number, seed *terminal effect*,
  within‑wafer non‑uniformity, RMS roughness)
- **Photoresist patterning from GDSII** for through‑mask plating: open‑area
  fraction, feature CD, feature (in‑opening) vs applied current density, feature
  height, and the pattern‑density *loading effect* on thickness uniformity

Defaults describe an **acid copper‑sulfate damascene bath**, but any metal/bath
can be modeled by overriding constructor arguments.

## Files

```
lib/Physics/Electrodeposition.pm         OO plating model (+ POD API docs)
lib/Physics/Electrodeposition/GDSII.pm   GDSII reader/writer/flattener
lib/Physics/Electrodeposition/Pattern.pm Pattern (open area, density, loading)
examples/copper_300mm.pl                 Worked example: Cu on a 300 mm wafer
examples/copper_through_mask_gdsii.pl    Through‑mask Cu pillars from a GDSII
t/electrodeposition.t                    Core physics tests
t/gdsii.t                                GDSII reader/writer/flatten tests
t/pattern.t                              Pattern + patterned‑model tests
README.md                                This file
```

## Requirements

Perl 5.10+ with core modules only (`POSIX`, `Test::More`, `FindBin`). No CPAN
dependencies (the GDSII reader/writer is pure Perl).

## Install

```sh
perl Makefile.PL
make
make test
make install
```

## Quick start

```sh
# run the worked 300 mm copper example (prints the full report)
perl -Ilib examples/copper_300mm.pl

# run the through-mask (GDSII pattern) example
perl -Ilib examples/copper_through_mask_gdsii.pl

# run the tests
perl -Ilib t/electrodeposition.t      # or: prove -Ilib t/
```

## Usage

```perl
use Physics::Electrodeposition;

my $ecd = Physics::Electrodeposition->new(
    metal            => 'Copper',
    wafer_diameter   => 300,      # mm
    current_density  => 20,       # mA/cm^2 (galvanostatic)
    target_thickness => 1.0,      # um  (module solves for plating time)
    efficiency       => 0.97,     # cathodic current efficiency
    anode_type       => 'soluble',
);

print $ecd->report;                    # full formatted report

my $h   = $ecd->film_thickness_um;     # 1.0 um
my $P   = $ecd->power;                 # cell power, W
my $mb  = $ecd->mass_balance;          # hashref: species moles/grams
my $nu  = $ecd->nonuniformity_percent; # estimated within-wafer non-uniformity
```

Give `current_density` plus **either** `time` **or** `target_thickness`; the
module solves for whichever you omit.

## The physics

Internal units are CGS‑ish (cm, A/cm², mol/cm³, s, g); public convenience methods
return engineering units (µm, mA/cm², V, W).

### Growth — Faraday's law

```
m = Q · M · CE / (n · F)              deposited mass
h = j · t · M · CE / (n · F · ρ)      film thickness
r = j · M · CE / (n · F · ρ)          deposition rate
```
where `Q = I·t`, `I = j·A`, `A = π·(d/2)²`, `n` = electrons, `F` = Faraday
constant, `M` = molar mass, `ρ` = density, `CE` = current efficiency.

### Mass balance

- **Cathode:** `Mⁿ⁺ + n e⁻ → M` (removes one metal ion per atom plated)
- **Soluble anode:** `M → Mⁿ⁺ + n e⁻` (replenishes the bath — closed loop)
- **Inert anode:** `2 H₂O → O₂ + 4 H⁺ + 4 e⁻` (bath depletes, O₂ + acid produced)
- **Cathode side reaction** when `CE < 1`: `2 H⁺ + 2 e⁻ → H₂`
- **Additives** (accelerator/suppressor/leveler) consumed per amp‑hour of charge

### Power — lumped cell‑voltage model

```
V_cell = E_thermo + |η_act| + |η_conc| + I·R_solution + additive_drop
```
- `η_act` — Tafel activation overpotential `= (RT/αnF)·ln(j/j₀)`
- `η_conc` — concentration overpotential `= (RT/nF)·ln(1 − j/j_lim)`
- `I·R_solution` — ohmic drop `= j·gap/κ`
- `additive_drop` — extra kinetic suppression from the organic package

Then `P = V·I`, `E = P·t`, and specific energy in kWh/kg.

### Transport, uniformity & smoothness

- **Limiting current density** `j_lim = n·F·D·C_b / δ` (δ = diffusion boundary
  layer). Operating well below `j_lim` gives dense, bright, level films; near it
  gives rough/powdery growth.
- **Wagner number** `Wa = κ·(∂η/∂j)/L`. `Wa ≫ 1` → kinetics throw the current
  out uniformly; `Wa ≪ 1` → ohmic/primary distribution dominates and the **tool**
  (anode shields, segmented/virtual anode, flow baffles) must shape the field.
- **Terminal effect** (the key large‑wafer problem): current flows radially
  through the thin, resistive seed, so the center‑to‑edge voltage drop is
  `ΔV = j·R_s·R²/4` (with seed sheet resistance `R_s = ρ_seed/t_seed`). Because it
  scales with `R²`, it is far worse on 300 mm than 200 mm and drives **edge‑fast**
  plating. Severity is the ratio of `ΔV` to the wafer‑normal voltage `j·R_series`.
- **Within‑wafer non‑uniformity (WIWNU)** — a bounded, *uncompensated* estimate of
  the terminal‑effect‑driven edge/center swing (before tool countermeasures).
- **RMS roughness** — grows with thickness and `j/j_lim`, suppressed by leveling
  additives.

## Worked example — copper on a 300 mm wafer

`examples/copper_300mm.pl` plates **1.0 µm of Cu** at 20 mA/cm² from an acid
Cu‑sulfate bath with a soluble anode. Representative results:

| Quantity | Value |
|---|---|
| Cell current | 14.1 A |
| Plating time | 140 s (2.3 min) |
| Deposition rate | 0.43 µm/min |
| Final film thickness | **1.00 µm** |
| Cu deposited | 0.633 g (9.97 mmol) |
| Cell voltage | 0.55 V (IR drop is the largest term) |
| Power / energy | 7.8 W / 0.30 Wh |
| Specific energy | 0.48 kWh/kg Cu |
| j / j_lim | 0.51 (below the transport limit → good smoothness) |
| Terminal‑effect drop | 356 mV center‑to‑edge (bare 60 nm seed) |
| Uncompensated WIWNU | ~31 % → needs mitigation |

The script then prints a **sensitivity sweep** (current density vs time, power,
smoothness) and a **process‑design comparison** showing how a thicker seed, a
high‑resistance (high‑throwing‑power) chemistry, tighter flow, and a gentle
cold‑entry current cut the uncompensated WIWNU from ~31 % to ~7 %.

### Interpreting the uniformity result

A bare 60 nm seed plated at 20 mA/cm² on 300 mm shows a **strong terminal effect**
— this is real and is exactly why production Cu ECD uses thicker seeds, resistive
chemistries, edge thieves, and current ramps. The model reports the *uncompensated*
tendency so you can size those countermeasures.

## Photoresist patterning from GDSII (through‑mask plating)

Real plating is often **through‑mask**: a photoresist covers the field and metal
grows only in the openings (Cu pillars, micro‑bumps, RDL, MEMS). Feed the mask
geometry straight from a **GDSII** layout:

```perl
my $ecd = Physics::Electrodeposition->new(
    gdsii                 => 'reticle.gds',   # layout file
    pattern_layer         => 10,              # photoresist‑opening layer
    resist_thickness      => 50,              # µm (mask height, for aspect ratio)
    current_density       => 10,              # mA/cm² ...
    current_density_basis => 'active',        # ... referenced to the openings (ASD)
    target_thickness      => 40,              # µm pillar height
);
print $ecd->report;                            # now includes a PATTERN section
```

The pure‑Perl `GDSII` reader parses units, boundaries/boxes and **flattens the
SREF/AREF hierarchy** (translation, rotation, reflection, magnification, arrays);
`Pattern` turns the polygons on the chosen layer into the geometry the model
needs. A minimal GDSII **writer** is included so examples/tests synthesise their
own layouts.

### What patterning changes physically

- **Open fraction `D`** = open (plating) area ÷ field area (pattern density).
- **Two current densities.** The tool sets a total current; referenced to the
  wafer it is `j_applied`, but inside the openings the surface sees the **active**
  density `j_active = j_applied / D`. Growth, transport (`j_lim`) and kinetics use
  `j_active`; total current, seed terminal effect and bulk IR use `j_applied`.
  For the same charge, features grow **1/D× thicker** than a blanket film.
- **Loading (pattern‑density) effect.** With a globally fixed current, low‑density
  (isolated) openings draw current from a larger catchment and plate **thicker**
  than dense arrays: local thickness ∝ (local density)`^(−loading_exponent)`. The
  model maps density across the die and reports the within‑die non‑uniformity and
  the isolated‑to‑dense height ratio.
- **Aspect ratio / fill risk.** With `resist_thickness`, deep openings (AR ≥ 3)
  near the transport limit are flagged for seam/void risk.

### Worked example — through‑mask copper pillars

`examples/copper_through_mask_gdsii.pl` synthesises a reticle with a **dense**
(50 µm‑pitch) and a **sparse** (150 µm‑pitch) 25 µm bump field, then plates 40 µm
pillars at 10 mA/cm² active density. Representative results:

| Quantity | Value |
|---|---|
| Openings / CD | 2000 / 25 µm |
| Pattern density (open fraction) | 0.144 (14.4 % open) |
| Applied → active current density | 1.44 → 10.0 mA/cm² |
| Charge concentration | 6.96× into the openings |
| Feature (pillar) thickness | **40 µm** (blanket‑equivalent only 5.7 µm) |
| Cell current | 1.0 A (vs ~14 A for a blanket wafer) |
| Terminal‑effect drop | 8 mV (thick seed + low applied current) |
| **Loading within‑die NU** | **~56 %** (isolated pillars ~4× taller than dense) |
| Feature fill risk | LOW (9 % of j_lim, AR 2) |

The dominant non‑uniformity here is the **loading effect**, not the terminal
effect — the model makes that trade‑off explicit and points to levelers, a
resistive bath, or dummy‑fill as mitigations.

## API summary

| Method | Returns |
|---|---|
| `film_thickness_um`, `deposition_rate_um_min`, `process_time` | growth results |
| `mass_deposited`, `moles_deposited`, `charge`, `mass_balance` | chemistry mass balance |
| `cell_voltage`, `power`, `energy`, `specific_energy_kWh_kg` | electrical power |
| `limiting_current_density`, `current_fraction_of_limit` | transport limit |
| `wagner_number`, `terminal_effect_drop`, `terminal_effect_ratio` | current distribution |
| `nonuniformity_percent`, `roughness_nm`, `smoothness_verdict` | uniformity/smoothness |
| `open_fraction`, `j_applied`, `j_active`, `active_area`, `blanket_equivalent_thickness_um` | patterning |
| `loading_nonuniformity`, `isolated_to_dense_ratio`, `feature_aspect_ratio`, `fill_risk_verdict` | pattern effects |
| `report` | full formatted text report |

See the modules' POD (`perldoc lib/Physics/Electrodeposition.pm`, `…/GDSII.pm`,
`…/Pattern.pm`) for the complete list of constructor parameters and defaults.

## Caveats

The thickness, mass‑balance and power results are first‑principles. The
uniformity, roughness, loading and additive‑consumption figures are **calibrated
engineering estimates**, not a full 3‑D primary/secondary/tertiary current‑
distribution simulation. Pattern density assumes non‑overlapping mask openings
(polygon areas are summed, no Boolean union) and bins feature area onto a grid.
Use them for scoping, trade‑off studies and sensitivity analysis.
