# NAME

Test::Changes::Strict::Simple - Strict semantic validation for CPAN Changes files

# SYNOPSIS

    use Test::More;
    use Test::Changes::Strict::Simple qw(changes_strict_ok);

    changes_strict_ok('Changes');

    done_testing;

Typically used in `xt/release/` and guarded by:

    plan skip_all => 'Release tests only'
        unless $ENV{RELEASE_TESTING};

# DESCRIPTION

`Test::Changes::Strict::Simple` provides strict semantic validation for
CPAN-style `Changes` files.

While other modules focus primarily on structural validation,
this module performs additional consistency checks, including:

- The indentations must be uniform.
- No trailing spaces.
- No white characters other than spaces.
- No more than three blank lines at the end of the file.
- No version without items
- First line must be a title matching:

        qr/
           ^
            Revision\ history\ for\ (?:
              (?:perl\ )?
              (?:
                (?:module\ \w+(?:::\w+)*)
              |
                (?:distribution\ \w+(?:-\w+)*)
              )
            )
            $
          /x;

- Title lines and version lines are never indented.
- A version line consists of a version string and a date separated by blanks.
- Dates match `/\d+\.\d+/`.
- Versions are strictly monotonically increasing.
- Release dates are valid calendar dates.
- Release dates are not in the future.
- Release dates are not earlier than the first public Perl release (1987).
- Release dates are monotonically non-decreasing
(multiple releases on the same day are allowed).

Note: an item can span more than one line.

Example of a valid Changes file:

    Revision history for distribution Foo-Bar-Baz

    0.03 2024-03-01
      - Another version, same day.

    0.02 2024-03-01
      - Bugfix.
      - Added a very fancy feature that alllows this
        and that.
      - Another bugfix.

    0.01 2024-02-28
      - Initial release. This will hopefully work
        fine.

The module is intended for use in release testing and helps
detect common mistakes such as version regressions, invalid
dates, and chronological inconsistencies.

# EXPORT

By default, the following symbols are exported:

    changes_strict_ok

# IMPORT OPTIONS

## -check\_dots => _BOOL_

By default, items must end with a period. This check can be disabled by
passing `-check_dots` with a value of _`false`_. Example:

    use Test::Changes::Strict::Simple -check_dots => 0;

## -empty\_line\_after\_version => _BOOL_

By default, the first element must immediately follow the version line.
Passing `-empty_line_after_version` with a _`true`_ value changes this
behavior so that there must be exactly one blank line between a version line
and the first element. Example:

    use Test::Changes::Strict::Simple -empty_line_after_version => 1;

## -no\_export => _BOOL_

If true, no symbols are exported.

    use Test::Changes::Strict::Simple -no_export => 1;

is equivalent to:

    use Test::Changes::Strict::Simple ();

This option is useful in conjunction with other import options. Example:

    use Test::Changes::Strict::Simple -empty_line_after_version => 1, -no_export => 1

## -version\_re => _REGEXP_

By default, version numbers must match `qr/\d+\.\d+/`. This can be overridden
by passing a custom compiled regular expression via `-version_re`. Note that
version strings must be valid with respect to the `version` module.

# FUNCTIONS

## changes\_strict\_ok(_`NAMED_ARGUMENTS`_)

Runs strict validation on the given Changes file.

Named arguments:

- `changes_file`

    Optional. File to be validated. If no file is provided, `Changes` is assumed.

- `module_version`

    Optional. If specified, the function checks whether the highest version is
    equal to _`module_version`_. This is done by comparing strings.

The function emits one test event using `Test::Builder` and can output
diagnostic messages if necessary.
It does not plan tests and does not call `done_testing`.

Returns _`true`_ if all checks pass, _`true`_ otherwise.

# LIMITATIONS

The module expects a traditional CPAN-style Changes format:

    1.23 2024-03-01
      - Some change

Exotic or highly customized Changes formats may not be supported.

# SEE ALSO

- [Test::CPAN::Changes](https://metacpan.org/pod/Test%3A%3ACPAN%3A%3AChanges)

    Basic structural validation of CPAN Changes files.

- [Test::CPAN::Changes::ReallyStrict](https://metacpan.org/pod/Test%3A%3ACPAN%3A%3AChanges%3A%3AReallyStrict)

    Stricter validation rules for Changes files.

- [Test::Version](https://metacpan.org/pod/Test%3A%3AVersion)

    Checks module version consistency.

- [CPAN::Changes](https://metacpan.org/pod/CPAN%3A%3AChanges)

    Parser and model for Changes files.

Furthermore: [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder), [Time::Local](https://metacpan.org/pod/Time%3A%3ALocal), [version](https://metacpan.org/pod/version)

# AUTHOR

Klaus Rindfrey, `<klausrin at cpan.org.eu>`

# LICENSE

This software is copyright (c) 2026 by Klaus Rindfrey.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
