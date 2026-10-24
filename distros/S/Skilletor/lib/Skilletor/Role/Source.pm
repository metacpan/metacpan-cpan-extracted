package Skilletor::Role::Source;
# ABSTRACT: The interface of a source backend (local, git, url)

use strict;
use warnings;

use Moo::Role;

our $VERSION = '0.001';

requires qw( resolve check );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Role::Source - The interface of a source backend (local, git, url)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package My::Source;
  use Moo;
  with 'Skilletor::Role::Source';

  sub resolve { return { dir => $dir, version => 'local' } }
  sub check   { my ( $self, $cached_version ) = @_; return 1 }

=head1 DESCRIPTION

The reference's C<sources/types.ts>. A backend knows how to bring its source
to a local directory and how to tell cheaply whether it moved; it knows nothing
about templating or the target file system.

=head2 resolve

  my $loc = $source->resolve;
  # { dir => '/abs/tree', version => 'git:ab12cd3', warning => '...' }

Fetch or prepare the source. C<version> is opaque: C<local>, C<git:E<lt>shaE<gt>>,
C<etag:E<lt>etagE<gt>>, C<sha256:E<lt>hexE<gt>> or C<unknown>. C<warning> is set
when the backend fell back to a stale cache (offline). What a backend compares
with is its own cache's, never the caller's lock. Throws
L<Skilletor::Error::Source> when there is nothing to serve.

=head2 check

  my $changed = $source->check($cached_version);

Has the source changed since C<$cached_version>? True when it cannot tell.

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
