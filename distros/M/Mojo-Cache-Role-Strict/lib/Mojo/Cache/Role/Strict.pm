package Mojo::Cache::Role::Strict;
use Mojo::Base -role;
use Carp ();

with 'Mojo::Cache::Role::Exists';

our $VERSION = '0.05';

has [qw(strict_get strict_set)] => 1;

before get => sub {
    Carp::confess qq{unknown key '$_[1]'} if $_[0]->strict_get and not $_[0]->exists($_[1]);
};

before set => sub {
    Carp::confess 'cannot set in strict_set mode' if $_[0]->strict_set;
};

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Cache::Role::Strict - Limit get to keys that exist and prevent calls to set

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-Cache-Role-Strict"><img src="https://travis-ci.org/srchulo/Mojo-Cache-Role-Strict.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-Cache-Role-Strict?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-Cache-Role-Strict/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  my $strict_cache = Mojo::Cache->new
                                ->set(key_that_exists => 'I am here!')
                                ->with_roles('+Strict')
                                ;

  # prints "I am here!"
  say $strict_cache->get('key_that_exists');

  # get key that doesn't exist dies
  say $strict_cache->get('nonexistent_key');

  # setting new key dies
  $strict_cache->set(new_key => 'I die!');

  # updating existing key dies
  $strict_cache->set(key_that_exists => 'I die!');

  # allow nonexistent keys to be passed to get
  my $value = $strict_cache->strict_get(0)->get('nonexistent_key');

  # allow keys to be set
  $strict_cache->strict_set(0)->set(new_key => 'I live!');

=head1 DESCRIPTION

L<Mojo::Cache::Role::Strict> is a role that makes your L<Mojo::Cache> instance strict by
dying when calling L<Mojo::Cache/"get"> with keys that do not exist in the cache (have not
been set with L<Mojo::Cache/"set">) and by dying when you call L<Mojo::Cache/set>. You can optionally
allow L<Mojo::Cache/"get"> and L<Mojo::Cache/"set"> with L</strict_get> and L</strict_set>.

=head1 METHODS

=head2 exists

  if ($strict_cache->exists('key')) {
    my $value = $strict_cache->get('key');
    ...
  }

Returns C<true> if a cached value exists for the provided key, C<false> otherwise.

L</exists> is composed from L<Mojo::Cache::Role::Exists>. See that module for more information.

=head2 strict_get

  my $strict_cache = Mojo::Cache->new->with_roles('+Strict')->strict_get(0);

  # lives even though key does not exist
  my $value = $strict_cache->get('nonexistent_key');

L</strict_get> specifies whether keys must exist when calling L<Mojo::Cache/get>. If C<true>,
keys that do not exist will throw. If C<false>, C<undef> will be returned.

The default is C<true>.

This method returns the L<Mojo::Cache> object.

=head2 strict_set

  my $strict_cache = Mojo::Cache->new
                                ->set(key_that_exists => 'I am here!')
                                ->with_roles('+Strict')
                                ->strict_set(0)
                                ;

  # setting new key lives
  $strict_cache->set(new_key => 'I live!');

  # updating existing key lives
  $strict_cache->set(key_that_exists => 'new value');

L</strict_set> specifies whether L<Mojo::Cache/set> may be called. If C<true>,
calling L<Mojo::Cache/set> will throw. If C<false>, calls to L<Mojo::Cache/set> are allowed.

The default is C<true>.

This method returns the L<Mojo::Cache> object.

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
