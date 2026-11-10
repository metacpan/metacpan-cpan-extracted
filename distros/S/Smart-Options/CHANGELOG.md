# Changelog

All notable changes to Smart-Options are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions up to 0.061 were released from `Changes`, before this file existed.

## [Unreleased]

## [1.0.1] - 2026-11-10

- `Num` accepts integers (`3`, `-1`); it took only numbers with a decimal point
- An unknown type in `type` now dies with `cannot find type constraint '...'`; it was taken as `Config`

## [1.0.0] - 2026-11-10

- Version numbers have three parts from 1.0.0 on (`1.0.1`, `1.1.0`), and the change log moves from `Changes` to `CHANGELOG.md`
- **Breaking:** Require Perl 5.20 or later (`use 5.020`). 0.061 declared 5.10.1, and CI tested neither; CI now tests 5.20 and 5.44
- Drop the dependencies on `File::Slurp` and `List::MoreUtils`; `uniq` comes from `List::Util` 1.45
- A `Config` file that cannot be opened now dies with `cannot open config file '...': ...` (the message of `File::Slurp` before)
- Fix the documentation: the SYNOPSIS called `argv` as a method, which parsed the object itself, and the examples of `describe`, `demand` and `coerce` did not run as written. Document `env`, `env_prefix` and the `add_help` option of `new`
- Publish the contributors in the distribution metadata (`x_contributors`) with their GitHub noreply addresses
- Migrate CI from Travis CI and CircleCI to GitHub Actions

## [0.061] - 2017-05-11

- Fix `coerce` to return the object, so that it can be chained

## [0.06] - 2017-05-02

- Support environment variables (`env`, `env_prefix`)
- Support negated options (`--no-key`)
- Support several short options at once (`-abc`)
- Fix the documentation

## [0.056] - 2014-06-13

- Fix a coerced type to take its default value (thanks scott)

## [0.054] - 2014-06-02

- Fix the `Multiple` type (thanks hirobanex)

## [0.053] - 2013-05-27

- Stop using `given` / `when` (thanks takuji31)

## [0.052] - 2013-05-27

- Fix the dependencies in the distribution metadata (thanks takuji31)
- Stop the warnings on Perl 5.18 or later

## [0.051] - 2013-03-15

- Fix the dependencies in the distribution metadata (thanks hirobanex)

## [0.05] - 2013-01-27

- Support loading options from a file (the `Config` type)

## [0.04] - 2013-01-12

- Support type checks and coercion

## [0.03] - 2012-12-14

- Fix the tests on Windows (thanks NGLENN)
- Support the dot notation (`--foo.x=1`)

## [0.021] - 2012-11-29

- Fix `test_requires` and bugs of `alias` (thanks hayajo, [#1](https://github.com/kan/p5-smart-options/pull/1))

## [0.02] - 2012-11-13

- Support sub commands, like `Getopt::Compact::WithCmd`
- Support a DSL, like `opts` (`Smart::Options::Declare`)

## [0.01] - 2012-10-07

- Initial release

[1.0.1]: https://github.com/kan/p5-smart-options/releases/tag/v1.0.1
[1.0.0]: https://github.com/kan/p5-smart-options/releases/tag/v1.0.0
[0.061]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.061
[0.06]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.06
[0.056]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.056
[0.054]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.054
[0.053]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.053
[0.052]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.052
[0.051]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.051
[0.05]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.05
[0.04]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.04
[0.03]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.03
[0.021]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.021
[0.02]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.02
[0.01]: https://metacpan.org/release/MIKIHOSHI/Smart-Options-0.01
