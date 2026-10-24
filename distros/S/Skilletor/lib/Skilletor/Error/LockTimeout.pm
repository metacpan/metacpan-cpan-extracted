package Skilletor::Error::LockTimeout;
# ABSTRACT: Another run held the sync lock too long (the reference's SyncLockTimeoutError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::LockTimeout - Another run held the sync lock too long (the reference's SyncLockTimeoutError)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Thrown by L<Skilletor::State/with_lock> where the reference throws its C<SyncLockTimeoutError>. See L<Skilletor::Error> for the interface.

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
