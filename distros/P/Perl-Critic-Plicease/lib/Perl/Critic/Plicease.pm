package Perl::Critic::Plicease;

use strict;
use warnings;
use 5.010001;

# ABSTRACT: Some Perl::Critic policies used by Plicease
our $VERSION = '0.09'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Plicease - Some Perl::Critic policies used by Plicease

=head1 VERSION

version 0.09

=head1 DESCRIPTION

The L<Perl::Critic::Policy::Plicease> policies are an eclectic collection of
L<Perl::Critic> policies.  They aren't grouped into a theme because some are
application specific and you should review and include them only on a case by
case basis.

=over 4

=item L<Plicease::ProhibitLeadingZeros|Perl::Critic::Policy::Plicease::ProhibitLeadingZeros>

This is a slight remix on the prohibit leading zeros policy with some helpful exceptions.

=item L<Perl::Critic::Policy::Plicease::ProhibitSignaturesAndAtUnderscore>

Prohibit the use of C<@_> in subroutine using signatures

=item L<Perl::Critic::Policy::Plicease::ProhibitSpecificModules>

Prohibit the use of specific modules or pragmas

=item L<Plicease::ProhibitUnicodeDigitInRegexp|Perl::Critic::Policy::Plicease::ProhibitUnicodeDigitInRegexp>

Prohibit C<\d> (match any digit) in regular expressions without the C</a> or C</u> modifier.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ville Skyttä (SCOP)

Yoshikazu Sawa (yoshikazusawa)

Christian Walde (wchristian, MITHALDU)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
