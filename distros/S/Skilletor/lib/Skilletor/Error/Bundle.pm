package Skilletor::Error::Bundle;
# ABSTRACT: A bundle file is broken or cannot be expanded (the reference's BundleError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::Bundle - A bundle file is broken or cannot be expanded (the reference's BundleError)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Thrown by L<Skilletor::Bundles> where the reference throws its C<BundleError>. See L<Skilletor::Error> for the interface.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
