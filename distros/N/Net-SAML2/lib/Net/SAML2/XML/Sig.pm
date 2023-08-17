# After 10 years of XML::Sig existing in Net::SAML2 as
# Net::SAML2::XML::Sig the time has come to remove it and
# return to the use of XML::Sig proper.  At the time it was
# introduced XML::Sig was not being maintained but now XML::Sig
# and Net::SAML2 have a common maintainer and the need to keep it
# embedded no longer exists.  Indeed keeping the versions in sync
# has become more bother than it is worth.
use strict;
use warnings;
package Net::SAML2::XML::Sig; use base qw(XML::Sig);
our $VERSION = '0.73'; #VERSION
#
# ABSTRACT: Net::SAML2 subclass of XML::Sig

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::XML::Sig - Net::SAML2 subclass of XML::Sig

=head1 VERSION

version 0.73

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
