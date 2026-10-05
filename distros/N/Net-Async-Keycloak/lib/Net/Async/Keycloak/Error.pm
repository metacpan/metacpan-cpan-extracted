package Net::Async::Keycloak::Error;

# ABSTRACT: Exception base class for Net::Async::Keycloak

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Keycloak::Error - Exception base class for Net::Async::Keycloak

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    $kc->admin->get_client_f($id)->else( sub {
      my ( $error ) = @_;
      return Future->done(undef) if $error->isa('Net::Async::Keycloak::Error::API') && $error->is_not_found;
      return Future->fail($error);
    } );

=head1 DESCRIPTION

Failed futures of Net::Async::Keycloak fail with one of
L<Net::Async::Keycloak::Error::Validation>,
L<Net::Async::Keycloak::Error::Network> and
L<Net::Async::Keycloak::Error::API>. Each is also the matching
L<WWW::Keycloak::Error> class, and stringifies to its message.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-keycloak/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
