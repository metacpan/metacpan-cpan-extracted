# Physics::Etch

A Perl module that models both **wet** (isotropic, chemically driven) and
**dry** (anisotropic, plasma / RIE / ion) semiconductor etch processes, with a
small built-in database of materials and etch recipes.

It computes etch rate, anisotropy, feature profile (undercut, etch bias,
sidewall angle, aspect ratio), clear time and over-etch, mask selectivity /
survival, substrate over-etch, and across-wafer uniformity — and prints a
readable process report.

It also includes a **pattern / reactor toolkit** that models pattern-dependent
anisotropy and loading: a self-contained **GDSII** reader/writer for the resist
mask, **layout** geometry analysis (open area, per-feature CD, density map), a
**chamber** model (reactor geometry → DC bias, ion energy, mean free path,
residence time), **loading** effects (macro, micro and aspect-ratio-dependent
ARDE / RIE-lag), and a **simulation** that ties them together for per-feature
results.

> **Disclaimer:** the embedded rates, activation energies and selectivities are
> illustrative, order-of-magnitude teaching values, *not* process
> specifications. Every value is overridable at call time.

## Layout

```
lib/Physics/Etch.pm            facade + material/recipe database + factories
lib/Physics/Etch/Material.pm   material (film / mask / substrate)
lib/Physics/Etch/Etchant.pm    etchant / chemistry descriptor
lib/Physics/Etch/Process.pm    base class: geometry, selectivity, reporting
lib/Physics/Etch/WetEtch.pm    wet model  (Arrhenius, isotropic)
lib/Physics/Etch/DryEtch.pm    dry model  (power/pressure/bias, anisotropic)
lib/Physics/Etch/GDSII.pm      GDSII stream reader/writer (+ hierarchy flatten)
lib/Physics/Etch/Layout.pm     mask geometry: open area, CDs, density map
lib/Physics/Etch/Chamber.pm    reactor geometry -> plasma conditions
lib/Physics/Etch/Loading.pm    macro / micro loading + ARDE (RIE lag)
lib/Physics/Etch/Simulation.pm pattern+chamber+loading -> per-feature etch
examples/                      runnable scripts (one per material + toolkit)
t/                             Test::More suite (145 tests)
```

## Quick start

```perl
use Physics::Etch;

# Patterned copper, wet ferric-chloride etch
my $cu = Physics::Etch->wet_etch('copper',
    thickness      => 500,     # nm
    temperature    => 40,      # degC  (Arrhenius speed-up)
    feature_cd     => 3000,    # nm mask opening
    mask_thickness => 1500,
    overetch       => 0.30,
);
print $cu->report;

# Silicon-nitride RIE
my $sin = Physics::Etch->dry_etch('silicon_nitride',
    thickness => 200, feature_cd => 250,
    power => 250, pressure => 25, bias => 300,
);
print $sin->report;
```

Run a full report from the command line:

```sh
perl -Ilib examples/etch_copper.pl
```

## The physics

**Wet etch** (`WetEtch`) — chemical, essentially isotropic:

```
R(T) = rate * exp( (Ea/kB) * (1/Tref - 1/T) ) * concentration * agitation
lateral = R * isotropy            # isotropy defaults to 1.0 -> full undercut
```

Isotropy makes lateral rate ≈ vertical rate, so undercut ≈ etch depth and
sidewalls are sloped/rounded (~45°). Strong temperature activation (Arrhenius)
is the main rate knob.

**Dry etch** (`DryEtch`) — directional plasma / RIE, tunable anisotropy:

```
Rv = rate * (P/Pnom)^0.8 * (p/pnom)^0.3 * (Vb/Vbnom)^0.5 * loading * arrhenius
A_eff  = 1 - (1 - A_nom) * (p/pnom) * (Vbnom/Vb)      # clamped to [0,1]
lateral = Rv * (1 - A_eff)
```

Directional ion bombardment (high DC bias, low pressure) drives vertical
etching and steep sidewalls; high pressure / low bias lets radicals attack
laterally, lowering anisotropy and increasing undercut. An optional Arrhenius
term models hot dry etches (e.g. Cu in Cl₂).

**Derived by the base class** (`Process`): `time_to_clear`, `etch_time`
(clear × (1 + over-etch)), `etch_depth`, `undercut`, `anisotropy`,
`profile` (top/bottom width, etch bias, sidewall angle, aspect ratio),
`mask_loss` / `mask_survives`, `substrate_overetch`, `uniformity_report`,
and `report`.

## Pattern-dependent anisotropy, loading & chamber tools

The toolkit models how the **resist pattern** (from a GDSII file) and the
**reactor** combine to make etching feature-dependent.

```perl
use Physics::Etch;
use Physics::Etch::Loading;

my $etch    = Physics::Etch->dry_etch('silicon_nitride', thickness => 200);
my $chamber = Physics::Etch->chamber(
    wafer_diameter_mm => 200, gap_cm => 2.5,
    pressure_mtorr => 20, power_w => 300, flow_sccm => 80,
    gas => 'SF6', gas_mass_amu => 146, gas_diameter_m => 4.8e-10);
my $layout  = Physics::Etch->layout_from_gds('mask.gds',
    layer => 1, structure => 'TOP', tone => 'clear', field => [200,200]);
my $loading = Physics::Etch::Loading->from_chamber($chamber, arde_length => 5);

my $sim = Physics::Etch->simulate(
    process => $etch, chamber => $chamber,
    layout  => $layout, loading => $loading);
print $sim->report;               # per-CD anisotropy, undercut, RIE lag
```

- **GDSII input** (`GDSII`) — a self-contained reader/writer (no CPAN
  dependency, including the base-16 8-byte real codec). Flattens `SREF`/`AREF`
  hierarchies with reflection/magnification/rotation into absolute polygons.
- **Layout geometry** (`Layout`) — open area / open fraction (macro-loading
  input), per-feature CD from bounding boxes (ARDE input), and a local
  open-density grid (micro-loading input). `tone` selects clear vs dark field.
- **Chamber** (`Chamber`) — reactor geometry → electrode `area_ratio`,
  `power_density`, `residence_time` (`p·V/Q`), `mean_free_path`
  (`kT/√2·π·d²·p`), `knudsen`, and a heuristic DC `self_bias` / `ion_energy`.
  `process_conditions` hands pressure + bias straight to the dry etch.
- **Loading** (`Loading`) — macro `R/R₀ = 1/(1+κ·A_open)`, micro
  `1/(1+k·density)`, and ARDE / RIE-lag `1/(1+AR/AR₀)` (narrow features etch
  slower and taper). `from_chamber` estimates κ from residence time.
- **Simulation** (`Simulation`) — applies chamber conditions, macro loading
  from open area × wafer area, then per feature converts CD → aspect ratio →
  ARDE + micro-loading → local rate, depth, undercut, anisotropy, sidewall
  angle, and flags features that fail to clear (RIE lag).

## Examples

| Script | Material | Process shown |
|---|---|---|
| `etch_copper.pl`            | Patterned copper  | wet FeCl₃ **vs** dry Ar ion-mill (undercut) |
| `etch_photoresist_strip.pl` | Photoresist       | wet solvent / piranha strip |
| `etch_photoresist_ash.pl`   | Photoresist       | dry O₂ plasma ash + RIE trim |
| `etch_aluminum_silicide.pl` | Aluminum silicide | dry Cl₂/BCl₃ RIE (vs wet PAN undercut) |
| `etch_tantalum.pl`          | Tantalum          | dry SF₆ RIE (pressure/bias tuning) |
| `etch_titanium.pl`          | Titanium          | wet dilute-HF (SiO₂ selectivity) |
| `etch_silicon_nitride.pl`   | Silicon nitride   | wet hot H₃PO₄ (high Ea) + CF₄/O₂ RIE |
| `etch_polyimide.pl`         | Polyimide         | dry O₂ RIE thick-film via etch |
| `make_sample_mask.pl`       | —                 | writes `sample_mask.gds` (mixed CDs + densities) |
| `etch_gdsii_simulation.pl`  | Silicon nitride   | GDSII-driven per-feature anisotropy + RIE lag |
| `etch_loading_effect.pl`    | Aluminum silicide | macro (open-area) & micro (density) loading |
| `etch_chamber_geometry.pl`  | Silicon nitride   | reactor geometry → bias / mfp / anisotropy |

## Running the tests

```sh
prove -Ilib t/
```

## Install locally

With ExtUtils::MakeMaker:

```sh
perl Makefile.PL
make
make test
make install
```

On Windows with Strawberry Perl, use `gmake` instead of `make` if needed.

## Build and upload to CPAN

1. Build a release archive:

```sh
perl Makefile.PL
make dist
```

This creates `Physics-Etch-0.01.tar.gz`.

If `make dist` fails because `gzip` is unavailable on Windows, create it with:

```sh
perl -MIO::Compress::Gzip=gzip -e "gzip 'Physics-Etch-0.01.tar' => 'Physics-Etch-0.01.tar.gz' or die $IO::Compress::Gzip::GzipError"
```

2. Upload the tarball to PAUSE:
   - Log in at <https://pause.perl.org/>
   - Use **Upload a file to CPAN**
   - Upload `Physics-Etch-0.01.tar.gz`

After indexing completes, install from CPAN with:

```sh
cpanm Physics::Etch
```

## Extending

Add a material to `%MATERIAL` and a recipe hash to `@RECIPE` in
`lib/Physics/Etch.pm`, or bypass the database entirely and construct
`Physics::Etch::WetEtch` / `Physics::Etch::DryEtch` directly with your own
`rate`, `Ea`, `anisotropy`, etc.
