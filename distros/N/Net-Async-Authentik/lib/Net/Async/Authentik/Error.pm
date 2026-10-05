package Net::Async::Authentik::Error;

# ABSTRACT: Exception base class for Net::Async::Authentik

use Moo;
extends 'WWW::Authentik::Error';

our $VERSION = '0.001';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik::Error - Exception base class for Net::Async::Authentik

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    $ak->api->get_user_f($pk)->else( sub {
      my ( $error ) = @_;
      return Future->done(undef) if $error->isa('Net::Async::Authentik::Error::API') && $error->is_not_found;
      return Future->fail($error);
    } );

=head1 DESCRIPTION

A failed future of Net::Async::Authentik fails with one of
L<Net::Async::Authentik::Error::Validation>,
L<Net::Async::Authentik::Error::Network> and
L<Net::Async::Authentik::Error::API>. Nothing is thrown: a wrong argument
fails the future just as a refused request does, so one C<else> catches both.

Each of them is also the matching L<WWW::Authentik::Error> class, so code
written against the synchronous client catches them unchanged, and each
stringifies to its message.

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
