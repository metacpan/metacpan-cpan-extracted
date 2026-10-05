package Net::Async::Authentik::Error::Network;

# ABSTRACT: Raised when no HTTP answer came back from authentik

use Moo;
extends 'WWW::Authentik::Error::Network', 'Net::Async::Authentik::Error';

our $VERSION = '0.001';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik::Error::Network - Raised when no HTTP answer came back from authentik

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The same error as L<WWW::Authentik::Error::Network>, with the same attributes
and methods. It is both a L<WWW::Authentik::Error::Network> and a
L<Net::Async::Authentik::Error>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-authentik/issues>.

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
