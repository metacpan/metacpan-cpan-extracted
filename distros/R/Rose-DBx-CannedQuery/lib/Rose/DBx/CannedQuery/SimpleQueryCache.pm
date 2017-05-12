#!perl
#

use strict;
use warnings;

package Rose::DBx::CannedQuery::SimpleQueryCache;

our ($VERSION) = '1.00';

use Data::Dumper;
use Digest::MD5 qw(md5_hex);

use Moo 2;
use Types::Standard qw/ CodeRef Object /;

has backend => (
    isa      => Object,
    is       => 'ro',
    required => 1,
    lazy     => 1,
    builder  => '_build_backend'
);

has args_to_key => (
    isa      => CodeRef,
    is       => 'ro',
    required => 1,
    lazy     => 1,
    builder  => '_build_args_to_key'
);

sub _build_backend {
    Rose::DBx::CannedQuery::SimpleQueryCache::_PlainOldHash->new();
}

{
    my $dumper = Data::Dumper->new( [] )->Sortkeys(1);

    sub _make_digest_key {
        my (%args) = ref $_[0] ? %{ $_[0] } : @_;
        my $key =
          $dumper->Reset->Values( [ map { $_ => $args{$_} } sort keys %args ] )
          ->Dump;
        $key =~ s/\s+/ /g;
        $key = lc $key;
        $key = md5_hex($key) if length($key) > 512;
        return $key;
    }
}

sub _build_args_to_key {
    return \&_make_digest_key;
}

sub get_query_from_cache {
    my $self = shift;
    my $key  = $self->args_to_key->(@_);
    my $qry  = $self->backend->get($key);

    if ($qry) {
        my $sth = $qry->sth;

        # We take this roundabout path to check on connectedness because
        # $sth's own Active attribute may be false if prepared but not yet
        # executed, and we don't want to go through Rose::DB->dbh to get
        # DBI's database handle, since it'll reconnect under the hood if
        # it's been disconnected, which doesn't help $sth
        return $qry if $sth->{Active} or $sth->{Database}->{Active};
        $self->backend->remove($key);
    }
    return;
}

sub add_query_to_cache {
    my $self  = shift;
    my $query = shift;
    my $key   = $self->args_to_key->(@_);
    my $ret   = $self->backend->set( $key, $query );
    return $ret ? $query : $ret;
}

sub remove_query_from_cache {
    my $self = shift;
    my $key  = $self->args_to_key->(@_);
    return $self->backend->remove($key);
}

sub clear_query_cache {
    shift->backend->clear();
}

{

    package Rose::DBx::CannedQuery::SimpleQueryCache::_PlainOldHash;

    sub new {
        bless {}, shift;
    }

    sub get {
        my ( $self, $key ) = @_;
        return $self->{$key} if exists $self->{$key};
        return;
    }

    sub set {
        my ( $self, $key, $query ) = @_;
        $self->{$key} = $query;
        return $query;
    }

    sub remove {
        my ( $self, $key ) = @_;
        delete $self->{$key};
    }

    sub clear {
        my $self = shift;
        undef %$self;
        return 1;
    }
}

1;

__END__


=head1 NAME

Rose::DBx::CannedQuery::SimpleQueryCache - simple canned query cache

=head1 SYNOPSIS

  use Rose::DBx::CannedQuery::SimpleQueryCache;
  my $cache =
     Rose::DBx::CannedQuery::SimpleQueryCache->new(
       backend => CHI->new(...),
       args_to_key => \&my_converter
     );
  my $canned = $cache->get_query_from_cache(%desc);
  my $canned = $cache->add_query_to_cache($canned_query, %desc);
  $cache->remove_query_from_cache(%desc); # Drop one query
  $cache->clear_query_cache(); # Drop them all

=head1 DESCRIPTION

This class provides a simple API and default implementation for the
query cache available through L<Rose::DBx::CannedQuery>.  The goal of
the query cache is to simplify the structure of programs that use
L<Rose::DBx::CannedQuery>: code elsewhere can reuse a canned query
with some frequency without being required to keep track of the query
object across function calls or the like.  Because query objects
involve live database connections, the duration of caching, and the
number of queries that can be cached, is generally limited.  In
particular, the default implementation does not contemplate freezing
and thawing of query objects.

The behavior of the query cache is determined by two attributes:

=head2 ATTRIBUTES

=over 4

=item backend

This is the object that provides the cache.  It must implement C<get>,
C<set>, C<remove>, and C<clear> methods; their behavior is fairly
obvious from their names.

You may provide any cache object that is compatible with the above
API; in particular, this is intended to accommodate cache modules that
conform to the L<CHI> API.  If you do not, a default backend is used
that provides a simple in-memory cache with no expiration or other
active management.

=item args_to_key(I<$args>)

This is a code reference to a function that uses the contents of the
hash reference I<$args> to construct a key compatible with the query
backend.

L<Rose::DBx::CannedQuery> passes the arguments given to its
constructor in I<$args>.  This means that the query cache may be aware
of database connection information and SQL code, but will not know
about bind parameter values for a specific execution of the canned
query.

The default implementation uses the stringified form of all the
arguments passed to it to generate the key. The order of arguments,
whitespace within arguments, and alphabetic case of strings are not
significant.

=back

=head2 METHODS

L<Rose::DBx::CannedQuery::SimpleQueryCache> objects provide the
following methods to manage the query cache:

=over 4

=item B<add_query_to_cache>(I<$query>,I<$args>)

Adds I<$query> to the cache, using the key generated from I<$args>,
which must be a hash reference.

Returns I<$query> if the backend's C<set> method returns a true value,
and whatever C<set> returned otherwise. 

=item B<get_query_from_cache>(I<$args>)

Retrieves from the cache the query whose key is specified by I<$args>.
If a query object is retrived, but neither its L<DBI/sth> nor the associated
L<DBI/dbh> has a true C<Active> attribute, the object is deleted from
the cache and discarded.

Returns the query object on success, and nothing on failure.

=item B<remove_query_from_cache>(I<$args>)

Deletes the query object whose key is specified by I<$args> from the cache.

Returns whatever the backend's C<remove> method returns (the default
backend returns the query object).

=item B<clear_query_cache>()

Clears the query cache entirely.

Returns whatever the backend's C<clear> method returns (the default
backend returns a true value).

=back

=head2 INTERNAL METHODS

Since L<Rose::DBx::CannedQuery::SimpleQueryCache> is built using
L<Moo>, you have the option of changing its default behavior by
creating a subclass that replaces its attribute defaults via the
standard builder methods:

=over 4

=item _build_backend

Creates the default object for the L</backend>.  Currently returns an object
implementing the simple hash-based cache described above.  For more
details about the required behavior of the cache backend, see
the L</backend> documentation above.

=item _build_args_to_key

Creates the default for the L</args_to_key> function.  Returns a code
reference whose calling sequence is described under L</args_to_key> above.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Rose::DBx::CannedQuery>, L<CHI>

=head1 DIAGNOSTICS

Any message produced by an included package.

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Charles Bailey

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=cut
