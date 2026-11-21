package Skilletor::Error::TOML;
# ABSTRACT: A value TOML cannot hold (the reference's TomlWriteError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.008000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::TOML - A value TOML cannot hold (the reference's TomlWriteError)

=head1 VERSION

version 0.008000

=head1 DESCRIPTION

Thrown by L<Skilletor::TOML/stringify_toml> where the reference throws its
C<TomlWriteError>: a non-integer number, a float that is not finite, a nested
table, an array of anything but strings, a value without a TOML form. The
message names the key (C<< <table>.<key>: ... >>). See L<Skilletor::Error> for
the interface.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
