# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in OpenStack::MetaAPI, please report
it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please use one of the following methods:

- **GitHub Private Vulnerability Reporting**:
  [Report a vulnerability](https://github.com/cpan-authors/OpenStack-MetaAPI/security/advisories/new)
  via GitHub's built-in private reporting feature.

- **Email**: Contact the maintainers directly at the email addresses listed
  in the distribution metadata on
  [MetaCPAN](https://metacpan.org/dist/OpenStack-MetaAPI).

Please include:

- A description of the vulnerability
- Steps to reproduce the issue
- The version of OpenStack::MetaAPI affected
- Any potential impact assessment

Note that this distribution talks to OpenStack clouds on your behalf.
Reports that concern credential handling, the authentication token, or the
construction of request URIs are of particular interest.

## Response

We will acknowledge receipt of your report and aim to provide an initial
assessment promptly. Security fixes will be prioritized and released as
soon as practical.

## Scope

This policy covers the OpenStack::MetaAPI distribution as published on CPAN
and maintained in this repository. Vulnerabilities in OpenStack itself, or
in the underlying OpenStack::Client distribution, should be reported to
their respective maintainers.
