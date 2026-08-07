[![Release](https://img.shields.io/github/release/giterlizzi/perl-SSVC.svg)](https://github.com/giterlizzi/perl-SSVC/releases) [![Actions Status](https://github.com/giterlizzi/perl-SSVC/workflows/CI/badge.svg)](https://github.com/giterlizzi/perl-SSVC/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-SSVC.svg)](https://github.com/giterlizzi/perl-SSVC) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-SSVC.svg)](https://github.com/giterlizzi/perl-SSVC) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-SSVC.svg)](https://github.com/giterlizzi/perl-SSVC) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-SSVC.svg)](https://github.com/giterlizzi/perl-SSVC/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-SSVC/badge.svg)](https://coveralls.io/github/giterlizzi/perl-SSVC)

# SSVC - Perl extension for SSVC (Stakeholder-Specific Vulnerability Categorization)

## Synopsis

```.pl
use SSVC;

$ssvc = SSVC->new(
  cisa => {
    exploitation             => 'active',
    automatable              => 'yes',
    technical_impact         => 'partial',
    mission_prevalence       => 'minimal',
    public_well_being_impact => 'irreversible',
  }
);

# Get the decision
say $ssvc->decision; # act

# Parse SSVC vector string (only SSVC::CISA implements a vector string grammar)
$ssvc = SSVC::CISA->from_vector_string('SSVCv2/E:A/A:Y/T:P/P:M/B:I/M:H/D:C/2025-01-01T00:00:00');

# Convert the SSVC object in "vector string"
say $ssvc; # SSVCv2/E:A/A:Y/T:P/P:M/B:I/M:H/D:C/2025-01-01T00:00:00

# Get the decision point value
say $ssvc->public_well_being_impact; # irreversible

# Convert SSVC in JSON in according of SSVC JSON Schema
$json = encode_json($ssvc);
```

## Supported methodoligies

| Methodology Key           | Name                            | Class                           |
|---------------------------|---------------------------------|---------------------------------|
| `cisa`                    | CISA Coordinator                | `SSVC::CISA`                    |
| `cisa_bod_26_04`          | CISA BOD 26-04 Response Model   | `SSVC::CISA::BOD2604`           |
| `coordinator_publication` | Publication Decision            | `SSVC::CoordinatorPublication`  |
| `coordinator_triage`      | Coordinator Triage              | `SSVC::CoordinatorTriage`       |
| `deployer`                | Deployer Decision Model         | `SSVC::Deployer`                |
| `supplier`                | Supplier Decision Model         | `SSVC::Supplier`                |


## Install

Using Makefile.PL:

To install `SSVC` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm SSVC


## Documentation

- `perldoc SSVC`
- https://metacpan.org/release/SSVC
- [Carnegie Mellon University] SSVC: Stakeholder-Specific Vulnerability Categorization (https://certcc.github.io/SSVC/)
- [CISA] Stakeholder-Specific Vulnerability Categorization Guide (https://www.cisa.gov/sites/default/files/publications/cisa-ssvc-guide%20508c.pdf)

## Copyright

 - Copyright 2025-2026 © Giuseppe Di Terlizzi
