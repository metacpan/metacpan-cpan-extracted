# Qmail::Deliverable

[![CI Tests](https://github.com/msimerson/Qmail-Deliverable/actions/workflows/ci.yml/badge.svg)](https://github.com/msimerson/Qmail-Deliverable/actions/workflows/ci.yml)

`qmail-smtpd` does not know if a user exists. Lots of resources are wasted by
scanning mail for spam and viruses for addresses that do not exist anyway.

A replacement smtpd written in Perl (such as `qpsmtpd`) can use this module to
quickly verify that a local email address is (probably) actually in use.

This distribution ships:

- **Qmail::Deliverable** — the core library that consults
  `/var/qmail/control/locals`, `/var/qmail/control/virtualdomains`, and
  `/var/qmail/users/assign`, then resolves `.qmail` files and vpopmail
  delivery rules.
- **qmail-deliverabled** — a small HTTP daemon that wraps the library so the
  privileged config files can be read by a root-owned daemon and queried by an
  unprivileged smtpd.
- **Qmail::Deliverable::Client** — a client module with the same public
  interface as the library, but querying the daemon over HTTP.
- **qmail_deliverable** — a qpsmtpd plugin that uses the client.

## Installation

```sh
perl Makefile.PL
make
make test
make install
```

## Dependencies

A functional qmail installation in its standard location (`/var/qmail`) is
required at runtime. The test suite ships its own fixture tree under
`t/fixtures/` and does not require a real qmail install.

## Documentation

Each component has its own POD:

```sh
perldoc Qmail::Deliverable
perldoc Qmail::Deliverable::Client
perldoc qmail-deliverabled
perldoc Qmail::Deliverable::Comparison
```

## Copyright

- Copyright (C) 2007 by Juerd Waalboer
- Copyright (C) 2024 by Matt Simerson

Released under the same terms as Perl itself; see the per-file POD or
the LICENSE / package metadata for the redistribution terms a packager has
selected.
