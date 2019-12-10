package Mojo::Cache::Role::Strict;

use Carp ();
use Role::Tiny;

with 'Mojo::Cache::Role::Exists';

our $VERSION = '0.02';

before get => sub { Carp::confess "unknown key '$_[1]'" unless $_[0]->exists($_[1]) };

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Cache::Role::Strict - Require that keys exist when getting cached values or throw

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-Cache-Role-Strict"><img src="https://travis-ci.org/srchulo/Mojo-Cache-Role-Strict.svg?branch=master"></a>

=head1 SYNOPSIS

  my $strict_cache = Mojo::Cache->new->with_roles('+Strict');

  $strict_cache->set(key_that_exists => 'I am here!');

  # prints "I am here!"
  say $strict_cache->get('key_that_exists');

  # dies
  say $strict_cache->get('nonexistent_key');

=head1 DESCRIPTION

L<Mojo::Cache::Role::Strict> is a role that makes your L<Mojo::Cache> instance strict by
dying when keys that are provided to L<Mojo::Cache/"get"> do not exist in the cache (have not
been set with L<Mojo::Cache/"set">).

=head1 METHODS

=head2 exists

  if ($cache->exists('key')) {
    ...
  }

Returns C<true> if a cached value exists for the provided key, C<false> otherwise.

L</exists> is composed from L<Mojo::Cache::Role::Exists>. See that module for more information.

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

L<Mojo::Cache::Role::Exists>

=back

=cut
