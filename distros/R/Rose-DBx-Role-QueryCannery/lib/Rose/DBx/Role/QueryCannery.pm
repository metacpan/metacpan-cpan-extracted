#!perl
#
# $Id$

use strict;
use warnings;

package Rose::DBx::Role::QueryCannery;

our ($VERSION) = '1.00';

use Module::Runtime qw( use_module );
use MooX::Role::Parameterized;

sub _load_if {
    my $pkg = shift;
    no strict 'refs';
    return $pkg if keys %{ $pkg . '::' };
    use_module($pkg);
}

use Moo::Role 2;

role {
    my $params = shift;

    my ( $canning_class, %datasource );

    if ( $params->{query_class} ) {
        $canning_class = _load_if( $params->{query_class} );
    }
    else {
        # We know these are in their own files, so we can use_module directly
        $canning_class =
          eval { use_module('Rose::DBx::CannedQuery::Glycosylated') }
          || use_module('Rose::DBx::CannedQuery');
    }

    foreach my $key (qw/ rdb rdb_class rdb_params /) {
        next unless $params->{$key};
        $datasource{$key} = $params->{$key};
        _load_if( $params->{$key} ) if $key eq 'rdb_class';
    }

    my $log_args = sub { return (); };
    if ( $canning_class->can('verbose') and $canning_class->can('logger') ) {
        $log_args = sub {
            my $consumer = shift;
            my (@args);
            push @args, verbose => $consumer->verbose || 0
              if $consumer->can('verbose');
            push @args, logger => $consumer->logger
              if $consumer->can('logger') && $consumer->logger;
            return @args;
        };
    } ## end if ( $canning_class->can...)

    my $create_query = sub {
        my ( $constructor, $obj, $sql, $opts ) = @_;
        $opts ||= {};
        my (%merged_args) = (
            $log_args->($obj),
            %datasource,
            sql => $sql,
            %$opts
        );
        return $canning_class->$constructor(%merged_args);
    };

    method 'build_query' => sub { $create_query->( 'new',           @_ ); };
    method 'get_query'   => sub { $create_query->( 'new_or_cached', @_ ); };

};

1;

__END__

=head1 NAME

Rose::DBx::Role::QueryCannery - Streamline canned query generation

=head1 SYNOPSIS

  package Munge::My::Data;

  use Moo 2;

  # Give ourselves verbosity and logging attributes (optional)
  with 'MooX::Role::Chatty';

  # Grab the cannery machinery
  use Rose::DBx::Role::QueryCannery;

  # Set up cannery to create queries using specified Rose::DB
  # connection info; will automatically try to load rdb_class
  # and a default canned query class
  Rose::DBx::Role::QueryCannery->apply(
    { rdb_class => 'My::RDB::Class',
      rdb_params => { type => 'my_db', domain => $server } } );

  ...

  $self->verbose(2);

  # Create a canned query
  my $qry = $self->build_query('SELECT useful, stuff FROM table');
  foreach my $row ($qry->results) {
    do_something($row);
  }

  # Fetch another, or create it if it doesn't exist, with logging
  # turned off during query execution
  my $other_qry =
    $self->get_query('SELECT other, stuff FROM table WHERE param = ?',
                     { verbose => 0 });

  while ( my($name, $resultset) = 
            each %{ $other_qry->do_many_queries(\%bind_sets) } ) {

    # This still logs, since we're stil at verbose(2) out here
    $self->remark("Handling result for bind params $name");

    do_something_else($resultset);
  }

=head1 DESCRIPTION

Sometimes, when you're writing code that interacts with a database,
you need to maintain a tight binding between the data in the database
and the data in your application.  In these cases, an ORM such as
L<Rose::DB::Object> or L<DBIx::Class> give you a detailed mapping, at
the cost of added design and executing overhead.

Often, however, you just need to get the data out of (or into) the
database, so your code can operate on it.  In this situation, it's
ueful to minimize the boilerplate needed to get to and from the
database.  L<Rose::DBx::CannedQuery> tries to do this for individual
queries, and L<Rose::DBx::CannedQuery::Glycosylated> abstracts away a
bit more repetitive code dealing with logging.  But these helpers
still require a certain amount of work to define the data source,
connect logging, and so forth.  As you use them you'll probably find
yourself writing similar (if briefer) boilerplate, especially if you
use several canned queries in your application.

F<Rose::DBx::Role::QueryCannery> is the next step down this path to
convenience.  It packages up the process of creating several canned
queries against a common database, so that typically you only need to
provide the SQL itself for each query.

Depending on your needs, you may find it most helpful to use
F<Rose::DBx::Role::QueryCannery> in either of two ways:

=over 4

=item *

For more straightforward cases, you can just compose
L<Rose::DBx::Role::QueryCannery> into your application or analytic class.
You tell F<Rose::DBx::Role::QueryCannery> at composition
time about your data source, and it will set up the cannery
appropriately.

=item *

For more complex applications where the cannery might be used in
different places, or if you find yourself using the same database in
multiple applications, you can use L<Rose::DBx::Role::QueryCannery> as
the foundation for a reusable database-specific cannery.  Depending on
your preferences, you might accomplish this by writing a simple
(non-parameterized) cannery role:

  package My::DB::Cannery;

  use Rose::DBx::Role::QueryCannery;
  use Moo::Role 2;

  Rose::DBx::Role::QueryCannery->apply(
    query_class => 'Rose::DBx::CannedQuery::Glycosylated',
    rdb_class => 'My::RDB',
    rdb_params => { domain => $ENV{MYDB_TESTING_DOMAIN} || 'production',
                    type => 'my_db' }
  );

  # Elsewhere . . . 
  package My::Analytic::Class;
  use Moo 2;
  with 'My::DB::Cannery';

  sub munge_item {
    my( $self, $item_id, $opts ) = @_;
    my $qry = $self->get_query('SELECT some, stuff FROM table WHERE item_id = ?');

    foreach my $row ($qry->do_one_query( $item_id )) {
      next unless validate_result($row->{some}, $item_id);
      update_summary_stats($row->{stuff});
    }
  }

Alternatively, if you prefer to separate query construction from other
code, you can build a factory class that composes
L<Rose::DBx::Role::QueryCannery> with appropriate parameters:

  package My::DB::CanningFactory;

  use Rose::DBx::Role::QueryCannery;
  use Moo 2;  # Not Moo::Role
  use MooX::ClassAttribute;

  # Get connection data from config, set up helper methods, etc.
  has 'verbose' => ( ... );
  sub _build_verbose { ... }
  has 'logger'  => ( ... );
  sub _build_logger { ... };
  class_has 'rdb'     => ( ... );
  sub _build_rdb { ... }

  Rose::DBx::Role::QueryCannery->apply(
    query_class => 'Rose::DBx::CannedQuery::Glycosylated',
    rdb => __PACKAGE__->rdb );

  # Elsewhere . . .
  package My::Analytic::Class;
  use Moo 2;
  use My::DB::CanningFactory;
  use Types::Standard 'InstanceOf';

  has 'cannery' => ( is => 'ro', required => 1, lazy => 1,
                     isa => InstanceOf['My::DB::CanningFactory'],
                     builder => '_build_cannery' );
  sub _build_cannery { 
    My::DB::CanningFactory->new( verbose => 2,
                                 logger => My::App::Logger->get_logger );
  }


  sub munge_item {
    my( $self, $item_id, $opts ) = @_;
    my $qry = 
      $self->cannery->get_query('SELECT some, stuff FROM table WHERE item_id = ?');

    foreach my $row ($qry->do_one_query( $item_id )) {
      next unless validate_result($row->{some}, $item_id);
      update_summary_stats($row->{stuff});
    }
  }

=back

=head1 PARAMETERS

You tell F<Rose::DBx::Role::QueryCannery> how to set up the cannery by
specifying as many of these parameters as you need at composition time
(using either the L<MooX::Role::Parameterized/apply> method or the
L<MooX::Role::Parameterized::With> class):

=over 4

=item query_class

This is the class that will actually construct and manage the canned
queries. You may specify any class whose query management is
compatible with L<Rose::DBx::CannedQuery>.  If you want automatic
logging, then the class needs to be compatible with
L<Rose::DBx::CannedQuery::Glycosylated>.

If you don't specify this class, and
L<Rose::DBx::CannedQuery::Glycosylated> can be loaded, it is used by
default.  If not, then L<Rose::DBx::CannedQuery> is tried.  If that
fails, an exception is thrown.

If the L</query_class> can respond to both C<verbose> and C<logger>
methods (i.e. is compatible with the logging interface of
L<Rose::DBx::CannedQuery::Glycosylated>), then the cannery introspects
your class for C<verbose> and C<logger> values, and uses them to
create canned queries.

=item rdb

This is a L<Rose::DB>-derived database handle used to manage the
database connection; see L<Rose::DBx::CannedQuery> for details.  There
is no default value.

As with L<Rose::DBx::CannedQuery>, you may specify either L</rdb> or
L</rdb_class> and L</rdb_params> when composing
L<Rose::DBx::Role::QueryCannery>.

=item rdb_class

This is the name of the L<Rose::DB>-derived class that makes the
database connection; see L<Rose::DBx::CannedQuery> for details.  There
is no default value.

=item rdb_params

This is a hash reference containing the data source information for
L</rdb_class>; again, see L<Rose::DBx::CannedQuery> for details.
There is no default value.

=back

=head1 METHODS

F<Rose::DBx::Role::QueryCannery> injects two methods into your class:

=over 4

=item B<build_query>(I<$sql>[, I<\%opts>])

Creates a new canned query using I<$sql> as the SQL, and taking the
rest of its defaults from the cannery.  If you want to override any of
the defaults for this query only, you may pass in the hash reference
I<\%opts> any of the parameters accepted by the C<new> constructor in
L</query_class>.

=item B<get_query>(I<$sql>[, I<\%opts>])

Does the same thing as L</build_query>, but calls the C<new_or_cached>
constructor in L</query_class>, so you can set up and retrieve
cached queries as well.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<Rose::DBx::CannedQuery>, L<Rose::DBx::CannedQuery::Glycosylated> for
canned queries.

L<MooX::Role::Chatty> for a simple way to set your class up with logging.

L<Rose::DBx::MoreConfig> or L<Rose::DB> for a database connection
class.

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
