package Mojo::Cache::Role::Exists;
use Mojo::Base -role;

our $VERSION = '0.02';

sub exists { CORE::exists $_[0]->{cache} && CORE::exists $_[0]->{cache}{$_[1]} }

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Cache::Role::Exists - Check if keys exist in the cache

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-Cache-Role-Exists"><img src="https://travis-ci.org/srchulo/Mojo-Cache-Role-Exists.svg?branch=master"></a>

=head1 SYNOPSIS

  my $cache = Mojo::Cache->new->with_roles('+Exists');
  if ($cache->exists('key')) {
    ...
  }

=head1 DESCRIPTION

L<Mojo::Cache::Role::Exists> allows you to check if keys exist in the cache via the L</exists> method.
Keys may not exist because they were never L<Mojo::Cache/"set">, or because they have been evicted from the cache.

=head1 METHODS

=head2 exists

  if ($cache->exists('key')) {
    ...
  }

Returns C<true> if a cached value exists for the provided key, C<false> otherwise.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious>

=item *

L<Mojo::Cache>

=item *

L<Mojo::Cache::Role::Strict>

=back

=cut
