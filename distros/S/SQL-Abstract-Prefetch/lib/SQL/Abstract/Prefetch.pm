package SQL::Abstract::Prefetch;

our $VERSION = '0.003';

=head1 NAME

SQL::Abstract::Prefetch - implement "prefetch" for DBI RDBMS

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.com/mohawk2/SQL-Abstract-Prefetch.svg?branch=master)](https://travis-ci.com/mohawk2/SQL-Abstract-Prefetch) |

[![CPAN version](https://badge.fury.io/pl/SQL-Abstract-Prefetch.svg)](https://metacpan.org/pod/SQL::Abstract::Prefetch) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/SQL-Abstract-Prefetch/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/SQL-Abstract-Prefetch?branch=master)

=end markdown


=head1 SYNOPSIS

  my $queryspec = {
    table => 'blog',
    fields => [
      'html',
      'id',
      'is_published',
      'markdown',
      'slug',
      'title',
      'user_id',
    ],
    keys => [ 'id' ],
    multi => {
      comments => {
        table => 'comment',
        fields => [ 'blog_id', 'html', 'id', 'markdown', 'user_id' ],
        keys => [ 'id' ],
      },
    },
    single => {
      user => {
        table => 'user',
        fields => [ 'access', 'age', 'email', 'id', 'password', 'username' ],
        keys => [ 'id' ],
      },
    },
  };
  my $abstract = SQL::Abstract::Pg->new( name_sep => '.', quote_char => '"' );
  my $dbh = DBI->connect( "dbi:SQLite:dbname=filename.db", '', '' );
  my $prefetch = SQL::Abstract::Prefetch->new(
    abstract => $abstract,
    dbhgetter => sub { $dbh },
    dbcatalog => undef, # for SQLite
    dbschema => undef,
    filter_table => sub { $_[0] !~ /^sqlite_/ },
  );
  my ( $sql, @bind ) = $prefetch->select_from_queryspec(
    $queryspec,
    { id => $items{blog}[0]{id} },
  );
  my ( $extractspec ) = $prefetch->extractspec_from_queryspec( $queryspec );
  my $sth = $dbh->prepare( $sql );
  $sth->execute( @bind );
  my ( $got ) = $prefetch->extract_from_query( $extractspec, $sth );

=head1 DESCRIPTION

This class implements "prefetch" in the style of L<DBIx::Class>. Stages
of operation:

=over

=item *

Generate a "query spec" that describes what you want back from the
database - which fields from which tables, and what relations to join.

=item *

Generate SQL (and bind parameters) from that "query spec".

=item *

Pass the SQL and parameters to a L<DBI> C<$dbh> to prepare and execute.

=item *

Pass the C<$sth> when ready (this allows for asynchronous operation)
to the extractor method to turn the returned rows into the hash-refs
represented, including array-ref values for any "has many" relationships.

=back

=head1 ATTRIBUTES

=head2 abstract

Currently, must be a L<SQL::Abstract::Pg> object.

=head2 dbhgetter

A code-ref that returns a L<DBI> C<$dbh>.

=head2 dbcatalog

The L<DBI> "catalog" argument for e.g. L<DBI/column_info>.

=head2 dbschema

The L<DBI> "schema" argument for e.g. L<DBI/column_info>.

=head2 filter_table

Coderef called with a table name, returns a boolean of true to keep, false
to discard - typically for a system table.

=head2 multi_namer

Coderef called with a table name, returns a suitable name for the relation
to that table. Defaults to L<Lingua::EN::Inflect::Number/to_PL>.

=head2 dbspec

By default, will be calculated from the supplied C<$dbh>, using the
supplied C<dbhgetter>, C<dbcatalog>, C<dbschema>, C<filter_table>,
and C<multi_namer>. May however be supplied, in which case those other
attributes are not needed.

A "database spec"; a hash-ref mapping tables to maps of the
relation-name (a string) to a further hash-ref with keys:

=over

=item type

either C<single> or C<multi>

=item fromkey

the column name in the "from" table

=item fromtable

the name of the "from" table

=item tokey

the column name in the "to" table

=item totable

the name of the "to" table

=back

The relation-name for "multi" will be calculated using
the C<multi_namer> on the remote table name.

=head1 METHODS

=head2 select_from_queryspec

Parameters:

=over

=item *

a "query spec"; a hash-ref with these keys:

=over

=item table

=item keys

array-ref of fields that are primary keys on this table

=item fields

array-ref of fields that are primitive types to show in result,
including PKs if wanted. If not wanted, the joins still function.

=item single

hash-ref mapping relation-names to "query specs" - a recursive data
structure; the relation is "has one"

=item multi

hash-ref mapping relation-names to "relate specs" as above; the relation is
"has many"

=back

=item *

an L<SQL::Abstract> "where" specification

=item *

an L<SQL::Abstract> "options" specification, including C<order_by>,
C<limit>, and C<offset>

=back

Returns the generated SQL, then a list of parameters to bind.

=head2 extractspec_from_queryspec

Parameters: a "query spec" as above.

Returns an opaque "extract spec": data to be used by
L</extract_from_query> to interpret results generated from the
L</select_from_queryspec> query.

=head2 extract_from_query

Parameters: an opaque "extract spec" created by
L</extractspec_from_queryspec>, and a L<DBI> C<$sth>.

Returns a list of hash-refs of items as reconstructed according to the spec.

=head1 SEE ALSO

L<Yancy::Backend>, L<DBI>, L<DBIx::Class>

=cut

use Mojo::Base '-base';
use Lingua::EN::Inflect::Number ();
use Scalar::Util qw( looks_like_number );

has 'abstract';
has 'dbhgetter';
has 'dbcatalog';
has 'dbschema';
has 'filter_table';
has multi_namer => sub { \&Lingua::EN::Inflect::Number::to_PL };
has dbspec => \&_build_dbspec;

sub select_from_queryspec {
  my ( $self, $queryspec, $where, $origopt ) = @_;
  my %opt = %{ $origopt || {} };
  my ( $talias, $sources, $columns ) = $self->_sc_from_queryspec(
    $queryspec,
  );
  $opt{order_by} = _order_by( $opt{order_by} || $queryspec->{keys}, $talias );
  my $limit = delete $opt{limit};
  my $offset = delete $opt{offset};
  my $abstract = $self->abstract;
  my %inner = %$queryspec;
  delete @inner{qw(single multi)};
  my ( undef, $inner_s, $inner_c ) = $self->_sc_from_queryspec( \%inner );
  my @inner_c2 = (@{ $queryspec->{keys} }, @{ $queryspec->{fields} });
  # this is to dedup colnames as MySQL blows up if select same column > 1 time
  # - at least in inner select - so use aliased ones for keys = already got
  my %keysmap = map {$_=>1} @{ $queryspec->{keys} };
  my $keyscount = @{ $queryspec->{keys} };
  $inner_c2[$_] = $inner_c->[$_]
    for grep $keysmap{$inner_c2[$_]}, $keyscount..$keyscount + $#{$queryspec->{fields}};
  my ( $inner_sql, @bind ) = $abstract->select(
    $inner_s,
    \@inner_c2,
    $where,
    (keys %opt ? \%opt : undef),
  );
  $inner_sql .= _limit_offset( $limit, $offset );
  return ( $inner_sql, @bind )
    if !%{ $queryspec->{single} || {} } and !%{ $queryspec->{multi} || {} };
  $inner_sql = "( $inner_sql ) as $talias";
  $sources->[0] = \$inner_sql;
  my ( $sql ) = $abstract->select(
    $sources,
    $columns,
    undef,
    (keys %opt ? \%opt : undef),
  );
  ( $sql, @bind );
}

sub _limit_offset {
  my ( $limit, $offset ) = @_;
  my $extra = '';
  if ( $limit ) {
    die "Limit must be number" if !looks_like_number $limit;
    $extra .= ' LIMIT ' . $limit;
  }
  if ( $offset ) {
    die "Offset must be number" if !looks_like_number $offset;
    $extra .= ' LIMIT ' . 2**32 if !$limit;
    $extra .= ' OFFSET ' . $offset;
  }
  $extra;
}

sub _order_by {
  my ( $order, $talias ) = @_;
  return undef if !$order;
  if ( ref $order eq 'ARRAY' ) {
    return [ map _order_by( $_, $talias ), @$order ];
  } elsif ( ref $order eq 'HASH' ) {
    my @o_b = %$order;
    return { $o_b[0] => "$talias.$o_b[1]" };
  } else {
    return "$talias.$order";
  }
}

# SQLA sources, columns
sub _sc_from_queryspec {
  my ( $self, $queryspec, $calias, $talias ) = @_;
  $calias //= 'c000';
  $talias //= 't000';
  my $my_talias = ++$talias;
  my $coll = $queryspec->{table};
  my $dbspec = $self->dbspec;
  my $abstract = $self->abstract;
  my $sep = $abstract->{name_sep};
  my @sources = ( \( $abstract->_quote( $coll ) . ' as ' . $my_talias ) );
  my @columns = map [ qq{$my_talias.$_}, ++$calias ],
    @{ $queryspec->{keys} || [] },
    @{ $queryspec->{fields} || [] };
  my $single = $queryspec->{single} || {};
  my $multi = $queryspec->{multi} || {};
  my %allrelations = ( %$single, %$multi );
  for my $relname ( sort( keys %$single ), sort( keys %$multi ) ) {
    my $relation = $allrelations{ $relname };
    my $other_coll = $relation->{table};
#use Test::More; diag "fkinfo all($coll=$my_talias) ", explain $dbspec->{ $coll };
    my $fkinfo = $dbspec->{ $coll }{ $relname };
#use Test::More; diag 'fkinfo ', explain $fkinfo;
    ( my $to_talias, my $other_s, my $other_c, $calias, $talias ) =
      $self->_sc_from_queryspec( $relation, $calias, $talias );
    my $totable =
      \( $abstract->_quote( $fkinfo->{totable} ) . ' as ' . $to_talias );
    my $tokey = $to_talias . $sep . $fkinfo->{tokey};
    my $fromkey = $my_talias . $sep . $fkinfo->{fromkey};
    $other_s->[0] = [ -left => $totable, $tokey, $fromkey ];
    push @sources, @$other_s;
    push @columns, @$other_c;
  }
#use Test::More; diag 'sfr so far ', explain [ \@sources, \@columns ];
  ( $my_talias, \@sources, \@columns, $calias, $talias );
}

# each "strip" = hashref:
#  keys=start,finish
#  fields=start,finish
#  fieldnames
#  offset
#  type (single=0, multi=1)
#  specsindex
#  subspecs (arrayref of pairs: [key, spec])
sub extractspec_from_queryspec {
  my ( $self, $queryspec, $offset, $type, $myspecsindex ) = @_;
  $myspecsindex //= 0;
  my $specsindex = $myspecsindex;
  $offset //= 0;
  $type //= 1; # default = top-level, which is a special-case multi
  my $keyscount = @{ $queryspec->{keys} };
  my @fields = @{ $queryspec->{fields} };
  my $highcount = $keyscount + $#fields;
  my @specs = {
    keys => [ 0, $keyscount - 1 ],
    fields => [ $keyscount, $highcount ],
    fieldnames => \@fields,
    offset => $offset,
    type => $type,
    specsindex => $myspecsindex,
  };
  my @subspecs;
  $offset += $highcount + 1;
  my $single = $queryspec->{single} || {};
  my $multi = $queryspec->{multi} || {};
  for (
    ( map [ 0, $_, $single->{$_} ], sort keys %$single ),
    ( map [ 1, $_, $multi->{$_} ], sort keys %$multi ),
  ) {
    ( my $otherspecs, $offset, $specsindex ) = $self->extractspec_from_queryspec(
      $_->[2],
      $offset,
      $_->[0], # single
      ++$specsindex,
    );
    push @specs, @$otherspecs;
    push @subspecs, [ $_->[1], $otherspecs->[0] ];
  }
  $specs[0]->{subspecs} = \@subspecs;
#use Test::More; diag "esfr ", explain [ $queryspec, \@specs ];
  ( \@specs, $offset, $specsindex );
}

sub extract_from_query {
  my ( $self, $extractspec, $sth ) = @_;
  my @ret;
  my @index2ids; # ids = array-ref of the PKs for this spec we are "on"
  # entrypoint = ref to update if new; scalar for single, array for multi
  my @index2entrypoint = ( \@ret ); # zero-th is the overall return
  while ( my $array = $sth->fetchrow_arrayref ) {
#use Test::More; diag 'after select, not undef ', explain $array;
    SPEC: for ( my $index = 0; $index < @$extractspec; $index++ ) {
      my $spec = $extractspec->[ $index ];
      my ( $kstart, $kend ) = map $spec->{offset} + $_, @{ $spec->{keys} };
      my $this_ids = [ @$array[ $kstart..$kend ] ];
      next SPEC if !grep defined, @$this_ids; # null PK = no result
      # not new object if both array-ref true and both lists identical
      next SPEC if ($index2ids[ $index ] and $this_ids)
        # this might be quicker if could rely on numerical, therefore !=
        and !grep $index2ids[ $index ][ $_ ] ne $this_ids->[ $_ ],
          0..$#{ $index2ids[ $index ] };
      _invalidate_ids( \@index2ids, $spec );
      $index2ids[ $index ] = $this_ids;
      my ( $fstart, $fend ) = map $spec->{offset} + $_, @{ $spec->{fields} };
      my %hash;
      @hash{ @{ $spec->{fieldnames} } } = @$array[ $fstart..$fend ];
      my $entrypoint = $index2entrypoint[ $spec->{specsindex} ];
      if ( $spec->{type} == 0 ) {
        # single, scalar-ref
        $$entrypoint = \%hash;
      } else {
        # multi, array-ref
        push @$entrypoint, \%hash;
      }
      $hash{ $_->[0] } = ( $_->[1]{type} == 0 ) ? undef : []
        for @{ $spec->{subspecs} };
      $index2entrypoint[ $_->[1]{specsindex} ] =
        ( $_->[1]{type} == 0 ) ? \$hash{ $_->[0] } : $hash{ $_->[0] }
        for @{ $spec->{subspecs} };
#use Test::More; diag "efr ", explain [ $array, $fstart, $fend, \%hash ];
    }
  }
  @ret;
}

sub _invalidate_ids {
  my ( $index2ids, $spec ) = @_;
  $index2ids->[ $spec->{specsindex} ] = undef;
  _invalidate_ids( $index2ids, $_->[1] ) for @{ $spec->{subspecs} };
}

sub _build_dbspec {
  my ( $self ) = @_;
  my ( $dbcatalog, $dbschema ) = ( $self->dbcatalog, $self->dbschema );
  my $dbhgetter = $self->dbhgetter;
  my @table_names = @{ $dbhgetter->()->table_info(
    $dbcatalog, $dbschema, undef, 'TABLE'
  )->fetchall_arrayref( { TABLE_NAME => 1 } ) };
  @table_names = grep $self->filter_table->($_), map $_->{TABLE_NAME},
    @table_names;
  s/\W//g for @table_names; # PostgreSQL quotes "user"
  my %dbspec;
  for my $table ( @table_names ) {
    # Pg returns undef if no FKs
    next unless my $fk_sth = $dbhgetter->()->foreign_key_info(
      undef, undef, undef, # PKT
      $dbcatalog, $dbschema, $table, undef
    );
    for (
      grep $_->{PKTABLE_NAME} || $_->{UK_TABLE_NAME}, # mysql
      @{ $fk_sth->fetchall_arrayref( {} ) }
    ) {
      my $totable = $_->{PKTABLE_NAME} || $_->{UK_TABLE_NAME};
      $totable =~ s/\W//g; # Pg again
      my $fromkey = $_->{FKCOLUMN_NAME} || $_->{FK_COLUMN_NAME};
      (my $fromlabel = $fromkey) =~ s#_?id$##; # simple heuristic
      my $tokey = $_->{PKCOLUMN_NAME} || $_->{UK_COLUMN_NAME};
      $dbspec{ $table }{ $fromlabel } = {
        type => 'single',
        fromkey => $fromkey, fromtable => $table,
        totable => $totable, tokey => $tokey,
      };
      $dbspec{ $totable }{ $self->multi_namer->( $table ) } = {
        type => 'multi',
        fromkey => $tokey, fromtable => $totable,
        totable => $table, tokey => $fromkey,
      };
    }
  }
  \%dbspec;
}

1;
