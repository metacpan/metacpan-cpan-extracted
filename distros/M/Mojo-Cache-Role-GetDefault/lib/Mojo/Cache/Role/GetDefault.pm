package Mojo::Cache::Role::GetDefault;
use Mojo::Base -role;

with 'Mojo::Cache::Role::Exists';

our $VERSION = '0.01';

requires qw(get set);

has 'default';

around get => sub {
    my $orig = shift;
    my $self = shift;
    my $key  = shift;

    if ((not @_ and not defined $self->default) or $self->exists($key)) {
        return $self->$orig($key);
    }

    my $default = @_ ? $_[0] : $self->default;
    my $value = ref $default eq 'CODE' ? do { local $_ = $key; $default->($key) } : $default;
    $self->set($key, $value);

    return $value;
};

sub clear_default { $_[0]->default(undef) }

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Cache::Role::GetDefault - Default values in get

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-Cache-Role-GetDefault"><img src="https://travis-ci.org/srchulo/Mojo-Cache-Role-GetDefault.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-Cache-Role-GetDefault?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-Cache-Role-GetDefault/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  my $cache = Mojo::Cache->new->with_roles('+GetDefault');

  # set 'abc' for $key in the cache if $key does not exist in the cache.
  # 'abc' will also be the return value
  my $value = $cache->get($key, 'abc');

  # sub is called and passed $key if $key does not exist in the cache.
  # Return value is set in cache for $key and returned by get.
  # $key is also available as the first argument
  my $value = $cache->get($key, sub { "default value for key $_" });

  # use get normally without any default value like in Mojo::Cache
  my $value = $cache->get($key);

  # set a default for all gets.
  # this default will be overridden by any default passed to get.
  $cache = $cache->default('abc');
  $cache = $cache->default(sub { ... });

=head1 DESCRIPTION

L<Mojo::Cache::Role::GetDefault> allows L<Mojo::Cache> to set and return default in L</get> when a key does not exist.

=head1 ATTRIBUTES

=head2 default

  my $default = $cache->default;
  $cache      = $cache->default('abc');

  # or use a sub that is passed the key as $_ and as the first argument
  $cache = $cache->default(sub { "default value for key $_" });
  $cache = $cache->default(sub { "default value for key $_[0]" });

The default value that is set and returned by L</get> if a key does not exist in the cache. L</default> may be a static value or
a subroutine that returns a value. The key is available to the subroutine as C<$_> and as the first argument.

You may clear L</default> with L</clear_default>.

L</default> will be overridden by any default passed to L</get>.

=head1 METHODS

=head2 get

=over 4

=item get($key, [$default])

=back

  # set 'abc' for $key in the cache if $key does not exist in the cache.
  # 'abc' will also be the return value
  my $value = $cache->get($key, 'abc');

  # sub is called and passed $key if $key does not exist in the cache.
  # Return value is set in cache for $key and returned by get.
  # $key is also available as the first argument
  my $value = $cache->get($key, sub { "default value for $_" });

  # use get normally without any default value like in Mojo::Cache
  my $value = $cache->get($key);

L</get> works like L<Mojo::Cache/get>, but allows an optional default value to be set and returned if the key does not
exist in the cache. C<$default> may be a static value or a subroutine that returns a value. The key is available
to the subroutine as C<$_> and as the first argument.

Any C<$default> passed to L</get> will override any default set in L</default>.

Providing no C<$default> makes L</get> behave exactly like L<Mojo::Cache/get>.

=head2 clear_default

  $cache = $cache->clear_default;

Clears any existing default set by L</default>.

=head2 exists

  if ($cache->exists($key)) {
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

=item

L<Mojo::Cache>

=item

L<Mojo::Cache::Role::Exists>

=item

L<Mojo::Base>

=back

=cut
