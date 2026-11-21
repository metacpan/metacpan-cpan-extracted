package Skilletor::Error::Bundle;
# ABSTRACT: A bundle file is broken or cannot be expanded (the reference's BundleError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.008000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::Bundle - A bundle file is broken or cannot be expanded (the reference's BundleError)

=head1 VERSION

version 0.008000

=head1 DESCRIPTION

Thrown by L<Skilletor::Bundles> where the reference throws its C<BundleError>. See L<Skilletor::Error> for the interface.

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
