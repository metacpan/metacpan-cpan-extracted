# Security Policy for the Perl-Critic-Policy-PreferredModules distribution.

This is the Security Policy for Perl::Critic::Policy::PreferredModules.

The latest version of the Security Policy can be found in the
[git repository for Perl-Critic-Policy-PreferredModules](https://github.com/cpan-authors/Perl-Critic-Policy-PreferredModules/blob/main/SECURITY.md).

This text is based on the CPAN Security Group's Guidelines for Adding
a Security Policy to Perl Distributions (version 1.3.0)
https://security.metacpan.org/docs/guides/security-policy-for-authors.html

# How to Report a Security Vulnerability

Please report security vulnerabilities to the maintainer by email at
<nicolas@atoomic.org>.

If you would like any help with triaging the issue, or if the issue
is being actively exploited, please copy the report to the CPAN
Security Group (CPANSec) at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue reporting system on GitHub
issues for reporting security vulnerabilities.

Please do not disclose the security vulnerability in public forums
until past any proposed date for public disclosure, or it has been
made public by the maintainers or CPANSec.  That includes patches or
pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainers aim to acknowledge your security report as soon as
possible.  However, this project is maintained by people in
their spare time, and they cannot guarantee a rapid response.  If you
have not received a response from them within 14 days, then
please send a reminder to them and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information.  It
will not necessarily include any fixes for the issue.

The project maintainers may forward this issue to the security
contacts for other projects where we believe it is relevant.  This
may include embedded libraries, system libraries, prerequisite
modules or downstream software that uses this software.

They may also forward this issue to CPANSec.

# Which Software This Policy Applies To

Any security vulnerabilities in Perl::Critic::Policy::PreferredModules
are covered by this policy.

Security vulnerabilities are considered anything that allows users
to execute unauthorised code, access unauthorised resources, or to
have an adverse impact on accessibility or performance of a system.

Security vulnerabilities in upstream software (prerequisite modules
or system libraries, or in Perl), are not covered by this policy
unless they affect Perl::Critic::Policy::PreferredModules, or
Perl::Critic::Policy::PreferredModules can be used to exploit
vulnerabilities in them.

Security vulnerabilities in downstream software (any software that
uses Perl::Critic::Policy::PreferredModules, or plugins to it that are
not included with the Perl-Critic-Policy-PreferredModules
distribution) are not covered by this policy.

## Supported Versions of Perl-Critic-Policy-PreferredModules

The maintainers will only commit to releasing security fixes for
the latest version of Perl-Critic-Policy-PreferredModules.

Note that this project only supports major versions of Perl
starting from v5.12.0.  If a security fix requires us to increase
the minimum version of Perl that is supported, then we may do so.

# Installation and Usage Issues

The distribution metadata specifies minimum versions of
prerequisites that are required for
Perl::Critic::Policy::PreferredModules to work.  However, some
of these prerequisites may have security vulnerabilities, and you
should ensure that you are using up-to-date versions of these
prerequisites.

Where security vulnerabilities are known, the metadata may indicate
newer versions as recommended.

## Usage

This policy is a static analysis tool.  It parses the code it
inspects and does not run it.  There is one exception, described
below, which you have to opt into.

### Configurations that load modules

A `[perl/<function>]` section combined with a `prefer` key asks the
policy whether the preferred module provides a replacement for that
builtin.  Answering that means resolving the module's exports, which
means loading the module, which runs its `BEGIN` blocks and top level
code inside the linting process.

Because that is more than static analysis is normally allowed to do,
the policy reports itself as unsafe when the configuration contains
such a section, and Perl::Critic leaves it out unless you pass
`-allow-unsafe`.  No other configuration loads anything: plain module
preferences, `for` lists, and `[perl/<function>]` sections without a
`prefer` key are all purely static and need no flag.

Only modules named by a `prefer` key in your own configuration file
are ever loaded.  Treat that configuration file as trusted input:
anyone who can edit it, or who can point the policy's `config`
setting at a file they control, can cause the module of their choice
to be loaded when you run `perlcritic` with `-allow-unsafe`.  Keep it
under the same access controls as the rest of your build tooling, and
be as careful with a `.perlcriticrc` and its `config` file taken from
an untrusted source as you would be with any other executable content.

Please see the software documentation for further information.
