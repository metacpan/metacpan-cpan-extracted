use strict;
use warnings;
package Software::Security::Policy::Individual;

our $VERSION = '0.03'; # VERSION

use parent 'Software::Security::Policy';
# ABSTRACT: The Individual Security Policy

sub name { 'individual' }
sub version {'0.1.8' }

1;

=pod

=encoding UTF-8

=head1 NAME

Software::Security::Policy::Individual - The Individual Security Policy

=head1 VERSION

version 0.03

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Timothy Legge <timlegge@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__SUMMARY__
# Security Policy for the {{ $self->program }} distribution.

Report issues via email at: {{ $self->maintainer }}.

__SECURITY-POLICY__
This is the Security Policy for the {{ $self->program }} distribution.

The latest version of this Security Policy can be found on the
{{ $self->program }} website at {{ $self->url }}

This text is based on the CPAN Security Group's Guidelines for Adding
a Security Policy to Perl Distributions (version 0.1.8)
https://security.metacpan.org/docs/guides/security-policy-for-authors.html

# How to Report a Security Vulnerability

Security vulnerabilities can be reported by e-mail to the current
project maintainers at {{ $self->maintainer }}

Please include as many details as possible, including code samples
or test cases, so that we can reproduce the issue.

If you would like any help with triaging the issue, or if the issue
is being actively exploited, please copy the report to the CPAN
Security Group (CPANSec) at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue reporting system on RT or
GitHub issues for reporting security vulnerabilities.

Please do not disclose the security vulnerability in public forums
until past any proposed date for public disclosure, or it has been
made public by the maintainers or CPANSec.  That includes patches or
pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainer(s) aim to acknowledge your security report as soon as
possible.  However, this project is maintained by a single person in
their spare time, and they cannot guarantee a rapid response.  If you
have not received a response from the them within {{ $self->timeframe }}, then
please send a reminder to them and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information.  It
will not necessarily include any fixes for the issue.

The project maintainer(s) may forward this issue to the security
contacts for other projects where we believe it is relevant.  This
may include embedded libraries, system libraries, prerequisite
modules or downstream software that uses this software.

They may also forward this issue to CPANSec.

# Which Software this Policy Applies to

Any security vulnerabilities in {{ $self->program }} are covered by this policy.

Security vulnerabilities are considered anything that allows users
to execute unauthorised code, access unauthorised resources, or to
have an adverse impact on accessibility or performance of a system.

Security vulnerabilities in upstream software (embedded libraries,
prerequisite modules or system libraries, or in Perl), are not
covered by this policy unless they affect {{ $self->program }}, or {{ $self->program }} can
be used to exploit vulnerabilities in them.

Security vulnerabilities in downstream software (any software that
uses {{ $self->program }}, or plugins to it that are not included with the
{{ $self->program }} distribution) are not covered by this policy.

## Supported Versions of {{ $self->program }}

The maintainer(s) will only commit to releasing security fixes for
the latest version of {{ $self->program }}.

Note that the {{ $self->program }} project only supports major versions of Perl
released in the past {{ $self->support_years }} years, even though {{ $self->program }} will run on
older versions of Perl.  If a security fix requires us to increase
the minimum version of Perl that is supported, then we may do so.

# Installation and Usage Issues

The distribution metadata specifies minimum versions of
prerequisites that are required for {{ $self->program }} to work.  However, some
of these prerequisites may have security vulnerabilities, and you
should ensure that you are using up-to-date versions of these
prerequisites.

Where security vulnerabilities are known, the metadata may indicate
newer versions as recommended.

## Usage

Please see the software documentation for further information.
