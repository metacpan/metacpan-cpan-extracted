# REQ.md — wiringPi version requirement catalog

The canonical minimum wiringPi version for the entire RPi:: distribution
family is **`RPi::Const::WIRINGPI_MIN_VERSION`** (currently **'3.18'**,
`:wiringpi` export tag, added in RPi::Const 1.07). This file catalogs every
distribution that requires wiringPi, and every file in each where the
requirement is called for — the checklist for any future version bump.

Consumption pattern for `Makefile.PL` guards (works even when RPi::Const
isn't installed yet at configure time):

```perl
my $min_wpi_ver = eval {
    require RPi::Const;
    RPi::Const::WIRINGPI_MIN_VERSION();
} || 3.18;
```

POD can't interpolate constants, so documentation states the number AND
points at the constant; those files are listed below so a bump updates them
in the same pass.

## Dists with the requirement called for (now consuming the constant)

| Dist | File | Site | Status |
|------|------|------|--------|
| WiringPi::API (`wiringpi-api`) | `Makefile.PL` | version guard (`$min_wpi_ver`) | ✅ uses constant, 3.18 fallback; RPi::Const prereq → 1.07 |
| WiringPi::API (`wiringpi-api`) | `lib/WiringPi/API.pm` DESCRIPTION | "requires wiringPi version 3.18+" | ✅ states 3.18+, points at constant |
| RPi::OLED::SSD1306::128_64 (`rpi-oled-ssd1306`) | `Makefile.PL` | version guard (was stale **2.36**) | ✅ uses constant, 3.18 fallback; RPi::Const 1.07 added to PREREQ_PM |
| RPi::OLED::SSD1306::128_64 (`rpi-oled-ssd1306`) | `lib/RPi/OLED/SSD1306/128_64.pm` DESCRIPTION | "requires wiringPi version ..." (was stale **2.36+**) | ✅ states 3.18+, points at constant |

## Dists that link wiringPi with NO version stated (candidates on next touch)

These link `-lwiringPi` in `Makefile.PL` (and/or document "requires
wiringPi") but never state a version. When any grows a version guard or a
versioned doc line, consume the constant per the pattern above.

| Dist | File(s) where wiringPi is called for | Site |
|------|--------------------------------------|------|
| RPi::ADC::MCP3008 (`rpi-adc-mcp3008`) | `Makefile.PL` (LIBS); `lib/RPi/ADC/MCP3008.pm` | versionless "Requires wiringPi" doc line |
| RPi::BMP180 (`rpi-bmp180`) | `Makefile.PL` (LIBS) | no doc mention |
| RPi::DHT11 (`rpi-dht11`) | `Makefile.PL` (LIBS); `lib/RPi/DHT11.pm` | versionless "requires the wiringPi library" doc line |
| RPi::DigiPot::MCP4XXXX (`rpi-digipot-mcp4xxxx`) | `Makefile.PL` (LIBS); `lib/RPi/DigiPot/MCP4XXXX.pm` | versionless "requires wiringPi" doc line |
| RPi::DAC::MCP4922 (`rpi-dac-mcp4922`) | `Makefile.PL` (LIBS) | no doc mention |
| RPi::HCSR04 (`rpi-hcsr04`) | `Makefile.PL` (LIBS); `lib/RPi/HCSR04.pm` (×2) | versionless "Requires wiringPi" doc lines |

## Related, not direct consumers

| Dist | Note |
|------|------|
| RPi::WiringPi (`rpi-wiringpi`) | No direct wiringPi link — requires it transitively via WiringPi::API. POD (`lib/RPi/WiringPi.pm` ~716) says wiringPi "must be installed prior", versionless. The broader single-source effort (BuildCheck module, tuple-compare fix, family audit gate) is tracked in `rpi-wiringpi/plans/wiringpi-version-single-source.md`. |
| RPi::Const (`rpi-const`) | Home of the constant: `lib/RPi/Const.pm` (`:wiringpi` tag), tests `t/49-wiringpi.t` + `t/50-const_coverage.t` manifest. |

## Known caveat (tracked, not fixed here)

The `Makefile.PL` guards compare with `version->parse`, which mis-orders
wiringPi's integer minors (3.8 parses as *newer* than 3.18). The constant is
the single source of the *value*; the compare-semantics fix is the
single-source plan's V3 (integer tuple compare in `RPi::Const::BuildCheck`).
