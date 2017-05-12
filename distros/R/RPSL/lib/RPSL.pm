package RPSL;
use strict;
use warnings;

our $VERSION = do { q$Revision: 27 $ =~ m{(\d+)}; $1 / 100; };

1;
__END__

=head1 NAME

RPSL - Router Policy Specification Language

=head1 SYNOPSIS

  perldoc RPSL

=head1 DESCRIPTION

ATTENTION: This module is just a placeholder. You probably want the
L<RPSL::Parser> module, if you're interested in parsing RPSL objects into Perl
code.

The RFC 2622 specifies a domain specific language named Router Policy
Specification Language (RPSL). This language is used by Regional Internet
Registries (RIRs), Local Internet Registries (LIRs) and Internet Service
Providers (ISPs) to describe their routing policies and connection related
information (like Autonomos Systems, administrative and technical contacts,
abuse mailboxes, etc).

The RPSL is used around the globe by people working with IP address space
management and abuse management to identify and cooperate with their
corresponding neighbour networks.

As this is a high-volume and somewhat complex non structured declarative
language, it's essential to be able to read and write it to several different
programming languages, in order to be able to automate the jobs related to
RPSL-encoded information. 

The purpose of all modules under the RPSL namespace is exactly this: provide a
standard, easy-to-use, RFC-compliant object-oriented programming library to
allow people to write programs able to read and write proper RPSL.

=head1 SEE ALSO

RFC 2622, the RPSL specification: L<http://tools.ietf.org/html/rfc2622>.

RFC 2650, a tutorial on how to use RPSL in the "Real World":
L<http://tools.ietf.org/html/rfc2650>.

RFC 4012, the new set of simple extensions to the RPSL language introduced in
2005: L<http://tools.ietf.org/html/rfc4012>.

L<RPSL::Parser>, a parser able to transform RPSL text into a Perl data
structrure.

=head1 AUTHOR

Luis Motta Campos, E<lt>lmc@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Luis Motta Campos

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut
