[![Release](https://img.shields.io/github/release/giterlizzi/perl-SBOM-CycloneDX.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX/releases) [![Actions Status](https://github.com/giterlizzi/perl-SBOM-CycloneDX/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-SBOM-CycloneDX.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-SBOM-CycloneDX.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-SBOM-CycloneDX.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-SBOM-CycloneDX.svg)](https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-SBOM-CycloneDX/badge.svg)](https://coveralls.io/github/giterlizzi/perl-SBOM-CycloneDX)

# SBOM::CycloneDX - Perl extension for CycloneDX

## Synopsis

```.pl
my $bom = SBOM::CycloneDX->new;

my $root_component = SBOM::CycloneDX::Component->new(
    type     => 'application',
    name     => 'MyApp',
    licenses => [SBOM::CycloneDX::License->new('Artistic-2.0')],
    bom_ref  => 'MyApp'
);

my $metadata = $bom->metadata;

$metadata->tools->add(cyclonedx_tool);

$metadata->component($root_component);

my $component1 = SBOM::CycloneDX::Component->new(
    type     => 'library',
    name     => 'some-component',
    group    => 'acme',
    version  => '1.33.7-beta.1',
    licenses => [SBOM::CycloneDX::License->new(name => '(c) 2021 Acme inc.')],
    bom_ref  => 'myComponent@1.33.7-beta.1',
    purl     => URI::PackageURL->new(
        type      => 'generic',
        namespace => 'acme',
        name      => 'some-component',
        version   => '1.33.7-beta.1'
    ),
);

$bom->components->add($component1);
$bom->add_dependency($root_component, [$component1]);

my $component2 = SBOM::CycloneDX::Component->new(
    type     => 'library',
    name     => 'some-library',
    licenses => [SBOM::CycloneDX::License->new(expression => 'GPL-3.0-only WITH Classpath-exception-2.0')],
    bom_ref  => 'some-lib',
);

$bom->components->add($component2);
$bom->add_dependency($root_component, [$component2]);

my @errors = $bom->validate;

if (@errors) {
    say $_ for (@errors);
    Carp::croak 'Validation error';
}

say $bom->to_string;
```

## Install

Using Makefile.PL:

To install `SBOM-CycloneDX` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using `App::cpanminus`:

    cpanm SBOM::CycloneDX


## Documentation

- `perldoc SBOM::CycloneDX`
- https://metacpan.org/release/SBOM-CycloneDX
- https://cyclonedx.org/

## Copyright

- Copyright 2025 © Giuseppe Di Terlizzi
