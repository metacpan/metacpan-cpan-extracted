# PDF::FacturX

[![CI](https://github.com/huguesmax/PDF-FacturX/actions/workflows/ci.yml/badge.svg)](https://github.com/huguesmax/PDF-FacturX/actions/workflows/ci.yml)
[![CPAN](https://img.shields.io/cpan/v/PDF-FacturX.svg)](https://metacpan.org/pod/PDF::FacturX)
[![License: Artistic 2.0](https://img.shields.io/badge/License-Artistic%202.0-blue.svg)](https://opensource.org/licenses/Artistic-2.0)

A Perl module to generate **Factur-X / ZUGFeRD**-compliant **PDF/A-3** invoices
(Franco-German hybrid PDF + XML standard, aligned with European Norm EN 16931).

Un module Perl pour générer des factures **PDF/A-3** conformes
**Factur-X / ZUGFeRD** (norme franco-allemande hybride PDF + XML, alignée
sur la norme européenne EN 16931).

---

## Table of contents / Sommaire

- [What is Factur-X / Qu'est-ce que Factur-X](#what-is-factur-x--quest-ce-que-factur-x)
- [Profiles / Profils](#profiles--profils)
- [Installation](#installation)
- [Usage](#usage)
- [Validators / Validateurs](#validators--validateurs)
- [Roadmap](#roadmap)
- [License / Licence](#license--licence)
- [Credits / Crédits](#credits--crédits)

---

## What is Factur-X / Qu'est-ce que Factur-X

### English

**Factur-X** is the joint Franco-German standard for hybrid electronic
invoicing, jointly published by:

- **FNFE-MPE** (Forum National de la Facture Electronique et des Marchés
  Publics Electroniques) in France
- **FeRD** (Forum elektronische Rechnung Deutschland) in Germany, where
  the same format is also known as **ZUGFeRD** (since version 2.1, ZUGFeRD
  and Factur-X are technically identical)

A Factur-X document is a single **PDF/A-3** file containing two payloads:

1. A **human-readable PDF** rendering of the invoice (any visual layout)
2. A **structured XML** payload following the UN/CEFACT Cross Industry
   Invoice (CII) syntax, attached to the PDF as an *associated file*
   (`AFRelationship = /Data`)

Factur-X is the reference format for the French B2B e-invoicing reform
mandated by article 153 of the 2020 amended finance law (Loi de finances
rectificative pour 2020), with mandatory rollout from 2026 to 2027. It is
also widely deployed in Germany alongside XRechnung (the public-sector
profile) for B2G and B2B exchanges.

### Français

**Factur-X** est la norme franco-allemande de facturation électronique
hybride, co-publiée par :

- **FNFE-MPE** (Forum National de la Facture Electronique et des Marchés
  Publics Electroniques) côté français
- **FeRD** (Forum elektronische Rechnung Deutschland) côté allemand, où
  ce même format est appelé **ZUGFeRD** (depuis la version 2.1, ZUGFeRD
  et Factur-X sont techniquement identiques)

Un document Factur-X est un fichier **PDF/A-3** unique contenant deux
charges utiles :

1. Un **rendu PDF lisible par l'humain** de la facture (toute mise en page)
2. Une **charge XML structurée** conforme à la syntaxe UN/CEFACT Cross
   Industry Invoice (CII), attachée au PDF en tant que *fichier associé*
   (`AFRelationship = /Data`)

Factur-X est le format de référence pour la réforme française de la
facturation électronique B2B prévue par l'article 153 de la loi de finances
rectificative pour 2020, avec déploiement obligatoire entre 2026 et 2027.
Il est également largement déployé en Allemagne aux côtés de XRechnung
(profil secteur public) pour les échanges B2G et B2B.

---

## Profiles / Profils

Factur-X 1.0.8 defines five conformance profiles. This module supports the
first four (the most widely used). EXTENDED is on the roadmap.

| Profile     | Lines | Tax breakdown | Payment | EN 16931 compliant |
|-------------|:-----:|:-------------:|:-------:|:------------------:|
| `minimum`   |  no   |      no       |   no    |        no          |
| `basicwl`   |  no   |     yes       |  yes    |       yes\*        |
| `basic`     | yes   |     yes       |  yes    |        yes         |
| `en16931`   | yes   |     yes       |  yes    |        yes         |
| `extended`  |  —    |       —       |   —     |        —           |

\* "WL" = Without Lines: header data only with VAT recap.

---

## Installation

### Prerequisites / Prérequis

- **Perl 5.20+**
- **Ghostscript 10.x or later** (system binary, in `PATH`)
- C library **libxml2** (used by `XML::LibXML`)

```sh
# Ubuntu / Debian
sudo apt-get install ghostscript libxml2-dev

# macOS (Homebrew)
brew install ghostscript libxml2
```

### From CPAN (when published)

```sh
cpanm PDF::FacturX
```

### From source / Depuis les sources

```sh
git clone https://github.com/huguesmax/PDF-FacturX.git
cd PDF-FacturX
cpanm --installdeps .
perl Makefile.PL
make
make test
make install
```

---

## Usage

### English — minimal example

```perl
use PDF::FacturX qw(generate);

my ($ok, $msg) = generate(
    pdf_in  => 'invoice-source.pdf',   # any visual PDF
    pdf_out => 'invoice-facturx.pdf',  # PDF/A-3 with XML attached
    profile => 'en16931',
    invoice => {
        number   => 'FA-2026-0042',
        date     => '2026-04-19',
        due_date => '2026-05-19',
        currency => 'EUR',
        seller   => {
            name      => 'Acme SARL',
            siret     => '12345678901234',
            vat       => 'FR12345678901',
            address_1 => '1 rue de la Paix',
            postcode  => '75001',
            city      => 'Paris',
            country   => 'FR',
        },
        buyer => {
            name      => 'Kunde GmbH',
            address_1 => 'Hauptstrasse 1',
            postcode  => '10115',
            city      => 'Berlin',
            country   => 'DE',
        },
        lines => [
            { name => 'Consulting', qty => 8, unit_price => 125,
              vat_rate => 20, vat_cat => 'S' },
        ],
        payment => {
            terms => 'Net 30',
            iban  => 'FR7612345678901234567890123',
            bic   => 'BNPAFRPP',
        },
    },
    title  => 'Invoice FA-2026-0042',
    author => 'Acme SARL',
);
die "Factur-X generation failed: $msg" unless $ok;
```

### Français — exemple minimal

Identique à l'exemple ci-dessus. Les messages d'erreur émis par la
validation interne sont en français.

### Lower-level API / API bas niveau

```perl
# Just build the XML (no PDF embedding)
use PDF::FacturX::XML qw(build_xml validate_xml);
my $xml = build_xml(\%invoice, 'basic');
my ($ok, $msg) = validate_xml($xml, 'basic');

# Just embed an existing XML into a PDF/A-3
use PDF::FacturX::Embed qw(embed_xml_pdfa3);
embed_xml_pdfa3(
    pdf_in  => 'src.pdf',
    xml     => $xml_string,
    pdf_out => 'out.pdf',
    profile => 'basic',
);
```

### Invoice hash schema / Schéma du hash facture

| Field / Champ            | Type     | Required / Requis     | Notes                                             |
|--------------------------|----------|-----------------------|---------------------------------------------------|
| `number`                 | string   | yes                   | invoice number                                    |
| `date`                   | string   | yes                   | ISO `YYYY-MM-DD`                                  |
| `due_date`               | string   | no                    | ISO `YYYY-MM-DD`                                  |
| `currency`               | string   | no (default `EUR`)    | ISO 4217, three uppercase letters                 |
| `type_code`              | int      | no (default `380`)    | 380 = invoice, 381 = credit note                  |
| `notes`                  | string   | no                    | free text                                         |
| `seller.name`            | string   | yes                   |                                                   |
| `seller.siret`           | string   | no                    | French SIRET (14 digits), schemeID `0002`         |
| `seller.vat`             | string   | no                    | EU VAT number (BTW/TVA/IVA/USt-IdNr.)             |
| `seller.address_*`       | string   | no                    |                                                   |
| `buyer.name`             | string   | yes                   |                                                   |
| `buyer.address_*`        | string   | no                    |                                                   |
| `lines[].name`           | string   | yes (basic, en16931)  |                                                   |
| `lines[].qty`            | number   | yes (basic, en16931)  |                                                   |
| `lines[].unit_price`     | number   | yes (basic, en16931)  |                                                   |
| `lines[].vat_rate`       | number   | yes (basic, en16931)  | percent, e.g. `20`, `5.5`                         |
| `lines[].vat_cat`        | string   | no (default `S`)      | one of `S Z E AE K G L M O`                       |
| `lines[].vat_exemption_reason` | string | no              | per-line override                                 |
| `vat_exemption_reason`   | string   | no                    | global default reason                             |
| `allowances[]`           | array    | no                    | global discounts/charges                          |
| `payment.terms`          | string   | no                    | free text                                         |
| `payment.iban`           | string   | no                    | SEPA credit transfer (IBAN)                       |
| `payment.bic`            | string   | no                    | SWIFT/BIC — `en16931` only (BT-86)                |

VAT categories (codes UNTDID 5305):

- `S` — standard rate
- `Z` — zero rate
- `E` — exempt
- `AE` — reverse charge (autoliquidation)
- `K` — VAT exempt for intra-community supplies
- `G` — exempt for export outside EU
- `L` — IGIC (Canary Islands)
- `M` — IPSI (Ceuta/Melilla)
- `O` — services outside scope of tax

---

## Validators / Validateurs

After generating a Factur-X PDF, validate it with one of the official
validators:

- **FNFE-MPE online validator** — https://services.fnfe-mpe.org/
  (free, accepts a PDF upload, returns conformance report)
- **Mustang CLI** (Java) — https://www.mustangproject.org/
  (offline validator, fully open source)
- **ZUGFeRD-Community Validator** — https://www.usegroup.de/zugferdcommunity/

---

## Roadmap

- [ ] EXTENDED profile support
- [ ] XRechnung profile (German B2G CIUS)
- [ ] Optional Mustang CLI integration in CI
- [ ] Programmatic Factur-X PDF *parsing* (extract attached XML + metadata)
- [ ] Native English error messages (currently French)

---

## License / Licence

This software is copyright (c) 2026 by huguesmax.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself: the
[Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).

See [`LICENSE`](LICENSE) for the full text.

Ce logiciel est sous copyright (c) 2026 huguesmax. Il est distribué
sous les mêmes termes que Perl 5 lui-même : licence
[Artistic 2.0](https://opensource.org/licenses/Artistic-2.0). Voir le
fichier [`LICENSE`](LICENSE) pour le texte complet.

---

## Commercial support / Support commercial

### English

`PDF::FacturX` is maintained by **huguesmax** at
[**Softalys**](https://softalys.com) — a software studio based in USA/France
specializing in invoicing, document automation, and Perl-based business
systems.

If you need help integrating Factur-X / ZUGFeRD into your workflow,
custom profile support (EXTENDED, XRechnung, sector-specific CIUS),
end-to-end consulting on the French e-invoicing reform (2026-2027), or
just a sanity-check on a tricky invoice, feel free to reach out:

- 🌐 **https://softalys.com**

The module is and will remain free and open source — paid support is for
those who want a guaranteed turnaround or hands-on help.

### Français

`PDF::FacturX` est maintenu par **huguesmax** au sein de
[**Softalys**](https://softalys.com) — un studio logiciel basé aux USA/France
spécialisé dans la facturation, l'automatisation documentaire et les
systèmes de gestion en Perl.

Pour toute aide à l'intégration de Factur-X / ZUGFeRD dans votre flux de
travail, un support sur les profils personnalisés (EXTENDED, XRechnung,
CIUS sectoriels), du conseil de bout en bout sur la réforme française de
la facturation électronique (2026-2027), ou simplement une relecture
d'une facture qui pose problème, n'hésitez pas à nous contacter :

- 🌐 **https://softalys.com**

Le module est et restera libre et open source — le support payant est
pour les besoins de garantie de délai ou d'accompagnement direct.

---

## Credits / Crédits

- **XSD schemas** bundled in `share/xsd/` are sourced from
  [akretion/factur-x](https://github.com/akretion/factur-x) (MIT License),
  aligned with the FNFE-MPE / FeRD official publication of Factur-X 1.0.8.
- **Bundled sRGB ICC profile** (`share/icc/sRGB.icc`) is the
  `default_rgb.icc` from [Artifex Ghostscript](https://www.ghostscript.com/),
  Apache License 2.0.
- Heavy lifting by [Ghostscript](https://www.ghostscript.com/) (PDF/A-3
  conversion) and [PDF::Builder](https://metacpan.org/pod/PDF::Builder)
  (final XMP metadata stream).

See [`NOTICE`](NOTICE) for full attributions.
