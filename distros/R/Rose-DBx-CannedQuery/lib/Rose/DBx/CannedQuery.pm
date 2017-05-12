#!perl
#

use strict;
use warnings;

package Rose::DBx::CannedQuery;

our ($VERSION) = '1.00';

use Carp;
use Scalar::Util;

use Moo 2;
use Rose::DB;    # Marker for prerequisite
use Types::Standard qw/ Str HashRef InstanceOf Object /;

has 'sql' => ( is => 'ro', isa => Str, required => 1 );

has 'rdb_class' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
    lazy     => 1,
    builder  => '_retcon_rdb_class'
);

sub _retcon_rdb_class {
    my $self = shift;
    Carp::croak "Can't recover Rose::DB class information without a handle"
      unless $self->_has_rdb;  # Use predicate to avoid recursion with _init_rdb
    my $class = Scalar::Util::blessed $self->rdb;

    # Ugly hack
    # Rose::DB creates handles in private classes; this may fail in the
    # future, as it relies on undocumented Rose::DB behavior
    $class =~ s/::__RoseDBPrivate__.*$//;
    return $class;
}

has 'rdb_params' => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
    lazy     => 1,
    builder  => '_retcon_rdb_params'
);

sub _retcon_rdb_params {
    my $self = shift;
    Carp::croak "Can't recover Rose::DB datasource information without a handle"
      unless $self->_has_rdb;  # Use predicate to avoid recursion with _init_rdb
    my $rdb = $self->rdb;
    return { type => $rdb->type, domain => $rdb->domain };
}

has 'rdb' => (
    is        => 'ro',
    isa       => InstanceOf ['Rose::DB'],
    required  => 0,
    lazy      => 1,
    predicate => '_has_rdb',
    builder   => '_init_rdb',
    handles   => ['dbh']
);

sub _default_rdb_params {
    return {
        connect_options => {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        }
    };
}

sub _init_rdb {
    my $self  = shift;
    my $class = $self->rdb_class;
    defined $class and eval "$class->can('new_or_cached') || require $class"
      or Carp::croak "Failed to load class $class: $@";
    return $self->rdb_class->new_or_cached( %{ $self->_default_rdb_params },
        %{ $self->rdb_params } );
}

has 'sth' => (
    is       => 'ro',
    isa      => Object,       # DBI's sth class is private
    required => 0,
    init_arg => undef,
    lazy     => 1,
    builder  => '_init_sth'
);

sub setup_dbh_for_query {
    my ($self) = @_;
    my $dbh = $self->rdb->dbh;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    return $dbh;
}

sub _init_sth {
    my $self = shift;
    my $dbh  = $self->setup_dbh_for_query;
    my $sth  = $dbh->prepare( $self->sql );
    unless ($sth) {
        Carp::croak 'Error preparing query: '
          . $dbh->errstr
          . "\nSQL was:\n\t"
          . join( "\n\t", split( /\n/, $self->sql ) ) . "\n";
        return;
    }
    return $sth;
}

sub execute {
    my ( $self, @args ) = @_;
    my $sth = $self->sth;

    unless ( $sth->execute(@args) ) {
        Carp::croak 'Error executing query: '
          . $sth->errstr
          . "\nArguments were:\n\t"
          . join( "\n\t", @args ) . "\n";
        return;
    }
    return $sth;
}

sub resultref {
    my ( $self, $args, $opts ) = @_;
    $opts ||= [ {} ];
    my $sth = $self->execute( @{ $args || [] } );
    return $sth->fetchall_arrayref(@$opts);
}

sub results {
    my ( $self, @args ) = @_;
    return @{ $self->resultref( \@args ) };
}

sub BUILDARGS {
    my ( $self, @args ) = @_;
    my $canon = $self->SUPER::BUILDARGS(@args);
    if ( not exists $canon->{rdb} ) {
        unless ( exists $canon->{rdb_class} ) {
            Carp::croak
              'Need either Rose::DB object or information to construct one';
            return;
        }
    }
    return $canon;
}

# Simple class data - at least for now, the added dependency of
# MooX::ClassAttribute seems more weight than it's worth
{
    my $Query_cache;

    sub _query_cache {
        my $self = shift;

        Carp::croak("_query_cache() may only be set via a class method call")
          if ref $self and @_;

        if (@_) {
            $Query_cache->clear() if $Query_cache;
            $Query_cache = $_[0];
        }
        elsif ( not defined $Query_cache ) {
            require Rose::DBx::CannedQuery::SimpleQueryCache;
            $Query_cache = Rose::DBx::CannedQuery::SimpleQueryCache->new();
        }

        return $Query_cache;
    }
}

sub new_or_cached {
    my ( $self, @args ) = @_;
    my $args_for_cache_key = ref $args[0] ? $args[0] : {@args};
    @args = {@args} unless ref $args[0];
    my $query = $self->_query_cache->get_query_from_cache($args_for_cache_key);
    if ( not $query ) {
        $query = $self->new(@args);
        $self->_query_cache->add_query_to_cache( $query, $args_for_cache_key )
          if $query;
    }
    return $query;
}

1;

__END__


=head1 NAME

Rose::DBx::CannedQuery - Conveniently manage a specific SQL query

=head1 SYNOPSIS

  use Rose::DBx::CannedQuery;
  my $qry = Rose::DBx::CannedQuery->new(rdb_class => 'My::DB',
              rdb_params => { type => 'real', domain => 'some' },
              sql => 'SELECT * FROM table WHERE attr = ?');
  foreach my $row ( $qry->results($bind_val) ) {
    do_something($row);
  }

  sub do_something_repeatedly {
    ...
    my $qry = Rose::DBx::CannedQuery->new_or_cached(rdb_class => 'My::DB',
              rdb_params => { type => 'real', domain => 'some' },
              sql => 'SELECT my, items FROM table WHERE attr = ?');
    # Exdcute query and manage results
    ...
  }

=head1 DESCRIPTION

This class provides a convenient means to execute specific queries
against a database fronted by L<Rose::DB> subclasses, in a manner
similar to (and I hope a bit more flexible than) the DBI's
L<DBI/selectall_arrayref> method.  You can set up the query once, then
execute it whenever you need to, without worrying about the mechanics
of the database connection.

The database connection is not actually made and the query is not
actually executed until you retrieve results or the active statement
handle.

=head2 ATTRIBUTES

The specifics of the query are passed as attributes at object
construction.  You may specify the database connection in either of
two ways:

=over 4

=item rdb_class

=item rdb_params

These describe, respectively, the L<Rose::DB>-derived class and the
parameters to be passed to that class' L<Rose::DB/new> method to
create the L<Rose::DB> object.  The L</rdb_params> attribute B<must>
be a hash reference, the single-argument shortcut allowed by
L<Rose::DB> to specify just a data source C<type> is not supported.

When the L<Rose::DB>>-derived object is created, the information in
F<rdb_params> will be merged with the class' default attributes, with
attributes in F<rdb_params> taking precedence. You may omit
L</rdb_params> if L</rdb_class> has default domain and type values
that point to a specific datasource; if this isn't the case,
L<Rose::DB> will die noisily.

F<Rose::DBx::CannedQuery> provides a small set of defaults:

  { connect_options =>
     { RaiseError => 1,
       PrintError => 0,
       AutoCommit => 1 
     }
  }

Subclasses may change or extend these defaults (see below).  The
merged parameters are then passed to the L</rdb_class>'
F<new_or_cached> constructor.

If a L<Rose::DBx::CannedQuery> object was created by passing in a
L<Rose::DB> database handle directly, the F<rdb_params> attribute
will return C<type> and C<domain> information only; if you want
more information about the handle, you can call L<Rose::DB> accessor
methods on it directly.

=item rdb

This is the L<Rose::DB>-derived object ("handle") managing the
database connection.  It may be supplied at connection time instead of
the F<rdb_class> and F<rdb_params> parameters, if you want to make
use of an already-constructed database handle.

=back

One or the other of these attribute sets must be provided when
creating a F<Rose::DBx::CannedQuery> object.

Other attributes are:

=over 4

=item sql

The SQL query that this object mediates is supplied as a string. This
attribute is required.

=item sth

The L<DBI> statement handle mediating the canned query.  This is a
read-only accessor; a statement handle cannot be specified at object
construction.

=back

=head2 CLASS METHODS

=over 4

=item new(I<%args>)

Create a new L<Rose::DBx::CannedQuery>, taking values for its
attributes from I<%args>.  In the style of L<Moose>, I<%args> may be
either a list of key-value pairs or a single hash reference.

The L</sql> attribute is required, as is either L</rdb> or enough of
L</rdb_class> and L</rdb_params> to construct a database handle.  If
L</rdb> is provided, it will be used regardless of the values in
L</rdb_class> and L</rdb_params>. Otherwise, L</rdb_class>'
L<Rose::DB/new_or_cached> will be called with the contents of
L</rdb_params> as parameters to obtain a new L<Rose::DB>-derived
database object.

=item new_or_cached(I<%args>)

Attempt to retrieve a cached L<Rose::DBx::CannedQuery> matching
I<%args>.  If successful, return the existing query object.  If not,
create a query via L</new> and add it to the cache.  See L</CACHING
QUERIES> for a description of the query cache

=back

=head2 OBJECT METHODS

=over 4

=item dbh

Convenience method that returns the L<DBI> database handle associated
with this object.  It is equivalent to C<< $obj->rdb->dbh >>.

=item setup_dbh_for_query

Establishes the L<DBI> database connection.  It also sets the
L<DBI/FetchHashKeyName> attribute on the handle to C<NAME_lc>, so the
methods below will by default return hash references with lowercase
keys.

Returns the L<DBI> database handle.

=item execute([I<@bind_args>])

Executes the query, binding the elements of I<@bind_args>, if any, to
placeholders in the SQL.  Returns a L<DBI> statement handle on
success, and raises an exception on failure.

You should use this method when you want to access the statement
handle directly for detailed control over how the results are
retrieved.

=item results([I<@bind_args>])

Calls L</execute>, passing I<@bind_args>, if any, and then fetches the
results.  In scalar context, returns the number of rows fetched.  In
array context, returns a list of hash references corresponding to rows
fetched.  The keys in each hash are the lower-case column names
(cf. L</setup_dbh_for_query>), and the values are the results for that
row, as described for L<DBI/fetchrow_hashref>.

=item resultref([I<$bind_args>, I<$query_opts>])

This method provides more flexibility than L</results>, at the cost of
a slightly more complex calling sequence.

Calls L</execute>, passing the contents of the array referenced by
I<$bind_args>, if any, and then fetches the results.  If present,
I<$query_opts> must be an array reference, whose contents are passed
to L<DBI/fetchall_arrayref>.  If I<$query_opts> is omitted, an empty
hash reference is passed, causing each row of the resultset to be
returned as a hash reference.

Returns the array reference resulting from the call to
L<DBI/fetchall_arrayref>.

=back

=head2 INTERNAL METHODS

These methods are exposed to facilitate subclassing, and should not
otherwise be used to interact with a F<Rose::DBx::CannedQuery> object.

=over 4

=item _default_rdb_params

This method returns a hash reference that supplies default parameters to
be passed to the L<Rose::DB>-derived constructor.  Specific parameters
will be overridden by equivalent keys in the L</rdb_params>
attribute. 

=item _retcon_rdb_class

This method is used to generate the value of the L</rdb_class>
attribute iff the object was constructed using an existing
L<Rose::DB>-derived object rather than connection parameters.

=item _retcon_rdb_params

This method is used to generate the value of the L</rdb_params>
attribute iff the object was constructed using an existing
L<Rose::DB>-derived object rather than connection parameters.  As
noted above, it is perhaps useful for reference, but is under no
obligation to accurately reproduce all of the parameters necessary to
construct a L<Rose::DB> handle just like the one owned by this object.

=item _init_rdb

Given the connection information in L</rdb_class> and
L</rdb_params>, construct a L<Rose::DB>-derived handle for the
L</rdb> attribute.  If necessary, you should arrange for L</rdb_class>
to be loaded.  An exception should be raised on failure; the
L<Rose::DB> constructor usually does this for you.

=item _init_sth

Given a validly constructed and connected F<Rose::DBx::CannedQuery>,
create a prepared L<DBI> statement handle for the query in L</sql>.
On success, you should return the statement handle.  On failure, you
should raise an exception.

=item BUILDARGS

The F<Rose::DBx::CannedQuery> F<BUILDARGS> simply checks that either a
L<Rose::DB>-derived handle or the necessary connection class and
parameters are provided.

=item _query_cache([I<$query_cache_object>)

If called without any parameters, returns the query cache currently in
use.  In this form, may be called as a class or object method, but
remember that the cache is class-wide, no matter how you retrieve it.

If called with I<$query_cache_object>, the current query cache (if
any) is cleared, and the query cache is set to I<$query_cache_object>,
which must conform to the API implemented by
L<Rose::DBx::CannedQuery::SimpleQueryCache>.  For simple variations on
the default behavior, you may be better served by supplying an
appropriately reconfigured L<Rose::DBx::CannedQuery::SimpleQueryCache>
instance than by writing a new cache class.

If you have not set the query cache explicitly (or if you set it to
C<undef>), an instance of L<Rose::DBx::CannedQuery::SimpleQueryCache>
will be lazily constructed using its default behaviors when a cache is
needed.

=back

=head1 CACHING QUERIES

Since one of the common uses for canned queries is execution of a
prepared SQL statement whenever a function is called,
L<Rose::DBx::CannedQuery> provides a (very!) simplistic cache to keep
queries around without requiring each place that might need the query
to maintain state.  You can use L</new_or_cached> as an alternative to
the regular L</new> constructor, and it will return to you the cached
version of a query, if any, in preference to creating a new one.

There are a few important limitations of this caching mechanism to
keep in mind:

=over 4

=item *

there is a single class-level query cache, so there will be at most
one query object compatible with any given set of parameters passed to
L</new_or_cached> at a time.  This cached object is returned in
whatever state the last user left it, so it may have already
L</execute>d using a particular set of bind values, or be in the midst
of fetching a resultset.

This may be construed as a feature, if you want to be able to pick up
where you left off in collecting results, but be careful if you plan
to retrieve the same query from multiple places.

=item *

the key used to determine whether a query is in the cache is up to the
cache class, which is passed the arguments that were given to
L</new_or_cached>.  The default key generating function for
L<Rose::DBx::CannedQuery::SimpleQueryCache> simply serializes the
arguments as a string.  This means that two calls that refer to the
same conceptual database operation in different ways (e.g. one which
says C<SELECT a FROM mytable ...> and another which says C<SELECT a
FROM mytable tab ...>) will result in creation and caching of two
queries.  Other cache classes may be smarter.

It also means the cache is not aware of any bind parameter values, so
it's not possible to simultaneously cache the same query being
executed with different bind parameters.

=item *

L<Rose::DBx::CannedQuery::SimpleQueryCache> (q.v.) makes an attempt to
insure that a cached query hasn't been disconnected since it was last
used.  However, the checks err on the side of low overhead rather than
comprehensiveness, and aren't foolproof.  If you plan to leave queries
untouched in the cache for a long time, you need to account for the
possibility that you'll get a stale query back (or you might want to
avoid the cache altogether, since the benefit is likely smaller).

If your application typically handles bursts of work with intervals of
rest in between (e.g. in responding to incoming requests), you may
benefit from caching queries while working, then explicitly clearing
the cache (e.g. by calling C<<
Rose::DBx::Cannedquery->_query_cache->clear >>) at the end of each
cycle. 

=back

=head1 EXPORT

None.

=head1 DIAGNOSTICS

Any message produced by an included package, as well as

=over 4

=item B<Need either Rose::DB object or information to constuct one> (F)

The constructor was called without either a L</rdb> attribute or
necessary L</rdb_class> and L</rdb_params> attributes.

=item B<Failed to load class> (F)

The L<Rose::DB>-derived class specified by L</rdb_class> either
couldn't be found or didn't load successfully.

=item B<Error preparing query> (F)

Something went wrong when trying to L<DBI/prepare> the L<DBI>
statement handle using L</sql>.

=item B<Error executing query> (F)

A problem was encountered trying to L<DBI/execute> the prepared query.
This could be a sign of a database problem, or it may reflect pilot
error, such as passing the wrong number of bind parameters.

=item B<Can't recover Rose::DB class information> (F)

=item B<Can't recover Rose::DB datasource information> (F)

Somehow we managed to get an object with neither L</rdb_class> or a
L</rdb> handle.  This shouldn't happen; it probably means a subclass
overrode F<BUILDARGS> and forgot to call the superclass method.

=back

=head1 BUGS AND CAVEATS

All query results are prefetched by the L</results> and L</resultref>
methods; if you want to iterate over a potentially large resultset,
you'll need to call appropriate L<DBI> methods on the statement handle
returned by L</execute>.

The default connection parameters include C<RaiseError>, and the
exceptions thrown when L</_init_sth> or L</execute> fails also include
the error information, so you may see it twice.  Better that than not
at all, if you happen to have changed the connection options in
L</rdb_params>.

=head1 BUT I<WHY?>

You might think, "What's the point?  How hard can it be to write a
little wrapper around straight DBI calls? Anybody who uses a database
has done that already.  Why should I bloat my dependency chain with
L<Rose::DB> and some object system?" or "Why is this different from
any of the other ORM or SQL-simplifier packages out there?" And you
may well be right, if you're dealing with a single database
connection, or are already up to your elbows in L<DBI> calls.

However, I find that this lands in a "sweet spot" for my coding
style. I find myself dealing with several databases on a recurring
basis, and L<Rose::DB> is a handy way to wrap up connection
information and credentials so they're easy to use elsewhere.  But
when I just want to pull some data, I don't necessarily need the
weight of an ORM.  L<Rose::DBx::CannedQuery> cuts down on the
boilerplate I need to make these queries, and lets me keep the
credentials separate from the code (particularly when using
L<Rose::DBx::MoreConfig>), without adding the overhead of converting
the results into objects.

Then there's the question, "What's with the Moo stuff?"  Sure,
L<Rose::DBx::CannedQuery> could be written using only "core" Perl
constructs.  But again, I find the L<Moo>y sugar makes the code
cleaner for me, and easier for someone else to subclass if they want
to.

In the end, I hope L<Rose::DBx::CannedQuery> makes your life sufficiently
easier that you find it worth using.  If it's close, but you think
it's not quite there, suggestions (better still, patches!) are happily
received. 

=head1 SEE ALSO

L<Rose::DB> and L<DBI> for more detailed information on options for
managing a canned query object.

L<Rose::DBx::MoreConfig> for an alternative to vanilla L<Rose::DB>
that lets you manage configuration data (such as server names and
credentials) in a manner that plays nicely with many CI and packaging
sytems.

If you're using L<Rose::DB::Object> as an ORM, see
L<Rose::DB::Object::Manager/make_manager_method_from_sql> for a
similar apprach that produces objects rather than raw results.

L<Moo> (or L<Moose>), if you're interested in subclassing

L<Rose::DBx::CannedQuery::SimpleQueryCache> for the default query cache

L<Rose::DBx::CannedQuery::Glycosylated> for slightly more sugary variant

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Charles Bailey

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=cut
