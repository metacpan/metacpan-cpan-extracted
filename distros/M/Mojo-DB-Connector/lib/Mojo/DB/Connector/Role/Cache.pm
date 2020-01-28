package Mojo::DB::Connector::Role::Cache;
use Mojo::Base -role;
use List::Util qw(pairs unpairs);
use Mojo::Cache;
use Mojo::Util ();

requires qw(_config _to_url new_connection);

has cache => sub { Mojo::Cache->new };

sub cached_connection {
    my $self     = shift;
    my %config   = $self->_config(@_);
    my $mojo_url = $self->_to_url(%config);

    # sort parameters so cached urls are the same
    $mojo_url->query(
        unpairs
        sort { $a->[0] cmp $b->[0] or $a->[1] cmp $b->[1] }
        pairs @{ $mojo_url->query->pairs }
    );
    my $cache_url = $mojo_url->userinfo(Mojo::Util::sha1_sum($mojo_url->userinfo // ''))->to_unsafe_string;

    my $connection;
    unless ($connection = $self->cache->get($cache_url)) {
        $connection = $self->new_connection(@_);
        $self->cache->set($cache_url => $connection);
    }

    return $connection;
}

1;
__END__

=encoding utf-8

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 NAME

L<Mojo::DB::Connector::Role::Cache> - Cache Mojo::DB::Connector connections

=head1 SYNOPSIS

  use Mojo::DB::Connector;

  my $connector = Mojo::DB::Connector->new->with_roles('+Cache');

  # fresh connection the first time
  my $connection = $connector->cached_connection(database => 'my_database');

  # later somewhere else...
  # same connection (Mojo::mysql or Mojo::Pg object) as before
  my $connection = $connector->cached_connection(database => 'my_database');

  # caching works with options
  my $connection = $connector->cached_connection(database => 'my_database', options => [PrintError => 1, RaiseError => 0]);

  # same connection as above, because options are sorted by key then value
  # before being used in the cache URL key as parameters
  my $connection = $connector->cached_connection(database => 'my_database', options => [RaiseError => 0, PrintError => 1]);

=head1 DESCRIPTION

L<Mojo::DB::Connector::Role::Cache> allows you to easily cache connections based on the connection settings and options.
A L<Mojo::URL> is created for each new or cached connection, and this is the cache key. A connection URL
may look like:

  mysql://batman:s3cret@localhost/db3

And if this connection URL is seen again, the same connection object (L<Mojo::mysql>) will be returned.
This caching even works with C<options> (L<Mojo::mysql/options>, L<Mojo::Pg/options>) because the C<options> are sorted
by key and then value before generating the URL:

  my $connection = $connector->cached_connection(database => 'my_database', options => [RaiseError => 0, PrintError => 1]);

  # the cache key for the above connection
  # note that RaiseError and PrintError have switched their order
  mysql://batman:s3cret@localhost/my_database?PrintError=1&RaiseError=0

=head1 ATTRIBUTES

=head2 cache

  my $cache  = $connector->cache;
  $connector = $connector->cache(Mojo::Cache->new);

  # set max number of connections to cache
  $connector->cache->max_keys(50);

L</cache> is a L<Mojo::Cache> that is used to cache connections.
By default it will cache 100 connections based on the default of L<Mojo::Cache/max_keys>.

=head1 METHODS

=head2 cached_connection

  my $connection = $connector->cached_connection(database => 'my_database');

  # works with options because options are sorted by key then value
  # before being used in the cache URL key as parameters
  my $connection = $connector->cached_connection(database => 'my_database', options => [RaiseError => 0, PrintError => 1]);

L</cached_connection> will return a cached connection if one is available, or generate and cache a new connection
to return. The cache key is a stringified L<Mojo::URL> (using L<Mojo::URL/to_unsafe_string>) that is based on the connection settings
and options. For example, different databases will generate different connections:

  my $connection       = $connector->cached_connection(database => 'my_database');
  my $other_connection = $connector->cached_connection(database => 'my_other_database');

And so will different options:

  my $connection       = $connector->cached_connection(database => 'my_database');
  my $other_connection = $connector->cached_connection(database => 'my_database', options => [RaiseError => 0]);

L</cached_connection> works with C<options> (L<Mojo::mysql/options>, L<Mojo::Pg/options>) because the C<options> are sorted
by key and then value before generating the URL.

L<Mojo::URL/userinfo> is hashed using L<Mojo::Util/sha1_sum> before being used in the cache key to ensure
that username and password information do not sit in memory.

See L</cache> for how to set L<Mojo::Cache/max_keys> to control how many connections
are cached.

=head1 SEE ALSO

=over 4

=item

L<Mojo::DB::Connector>

=item

L<Mojo::Cache>

=item

L<Mojo::DB::Connector::Role::ResultsRoles>

=back

=head1 LICENSE

This software is copyright (c) 2020 by Adam Hopkins.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=cut
