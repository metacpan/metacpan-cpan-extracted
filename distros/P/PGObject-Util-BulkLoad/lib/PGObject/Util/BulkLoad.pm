package PGObject::Util::BulkLoad;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use Memoize;
use Text::CSV;
use Try::Tiny;

=head1 NAME

PGObject::Util::BulkLoad - Bulk load records into PostgreSQL

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

To insert all rows into a table using COPY:
  my ($dbh, @objects);
  PGObject::Util::BulkLoad->copy(
      {table => 'mytable', insert_cols => ['col1', 'col2'], dbh => $dbh},
      @objects
  );

To copy to a temp table and then upsert:
  my ($dbh, @objects);
  PGObject::Util::BulkLoad->upsert(
      {table       => 'mytable',
       insert_cols => ['col1', 'col2'],
       update_cols => ['col1'],
       key_cols    => ['col2'],
       dbh         => $dbh},
      @objects
  );

Or if you prefer to run the statements yourself:

  PGObject::Util::BulkLoad->statement(
     table => 'mytable', type  => 'temp', tempname => 'foo_123'
  );
  PGObject::Util::BulkLoad->statement(
     table => 'mytable', type  => 'copy', insert_cols => ['col1', 'col2']
  );
  PGObject::Util::BulkLoad->statement(
      type        => 'upsert',
      tempname    => 'foo_123',
      table       => 'mytable',
      insert_cols => ['col1', 'col2'],
      update_cols => ['col1'],
      key_cols    => ['col2']
  );

If you are running repetitive calls, you may be able to trade time for memory
using Memoize by unning the following:

  PGObject::Util::BulkLoad->memoize_statements;

To unmemoize:

  PGObject::Util::BulkLoad->unmemoize;

To flush cache

  PGObject::Util::BulkLoad->flush_memoization;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 memoize_statements

This function exists to memoize statement calls, i.e. generate the exact same
statements on the same argument calls.  This isn't too likely to be useful in
most cases but it may be if you have repeated bulk loader calls in a persistent
script (for example real-time importing of csv data from a frequent source).

=cut

sub memoize_statements {
    return memoize 'statement';
}

=head2 unmemoize

Unmemoizes the statement calls.

=cut

sub unmemoize {
    return Memoize::unmemoize 'statement';
}

=head2 flush_memoization

Flushes the cache for statement memoization.  Does *not* flush the cache for
escaping memoization since that is a bigger win and a pure function accepting
simple strings.

=cut

sub flush_memoization {
    return Memoization::flush_cache('statement');
}

=head2 statement

This takes the following arguments and returns a suitable SQL statement

=over

=item type

Type of statement.  Options are:

=over

=item temp

Create a temporary table

=item copy

sql COPY statement

=item upsert

Update/Insert CTE pulling temp table

=item stats

Get stats on pending upsert, grouped by an arbitrary column.

=back

=item table

Name of table

=item tempname

Name of temp table

=item insert_cols

Column names for insert

=item update_cols

Column names for update

=item key_cols

Names of columns in primary key.

=item group_stats_by

Names of columns to group stats by

=back

=cut

sub _sanitize_ident {
    my ($string) = @_;
    $string =~ s/"/""/g;
    return qq("$string");
}

sub _statement_stats {
    my ($args) = @_;
    croak 'Key columns must array ref' unless (ref $args->{key_cols}) =~ /ARRAY/;
    croak 'Must supply key columns'    unless @{$args->{key_cols}};
    croak 'Must supply table name'     unless $args->{table};
    croak 'Must supply temp table'     unless $args->{tempname};

    my @groupcols;
    @groupcols =
        $args->{group_stats_by}
        ? @{$args->{group_stats_by}}
        : @{$args->{key_cols}};
    my $table = _sanitize_ident($args->{table});
    my $temp  = _sanitize_ident($args->{tempname});
    return "SELECT " . join(', ', map { "$temp." . _sanitize_ident($_) } @groupcols) . ",
            SUM(CASE WHEN ROW(" . join(', ', map { "$table." . _sanitize_ident($_) } @{$args->{key_cols}}) . ") IS NULL
                     THEN 1
                     ELSE 0
             END) AS pgobject_bulkload_inserts,
            SUM(CASE WHEN ROW(" . join(', ', map { "$table." . _sanitize_ident($_) } @{$args->{key_cols}}) . ") IS NULL
                     THEN 0
                     ELSE 1
            END) AS pgobject_bulkload_updates
       FROM $temp
  LEFT JOIN $table USING (" . join(', ', map { _sanitize_ident($_) } @{$args->{key_cols}}) . ")
   GROUP BY " . join(', ', map { "$temp." . _sanitize_ident($_) } @groupcols);
}

sub _statement_temp {
    my ($args) = @_;

    return "CREATE TEMPORARY TABLE " . _sanitize_ident($args->{tempname}) . " ( LIKE " . _sanitize_ident($args->{table}) . " )";
}

sub _statement_copy {
    my ($args) = @_;
    croak 'No insert cols' unless $args->{insert_cols};

    return
          "COPY "
        . _sanitize_ident($args->{table}) . "("
        . join(', ', map { _sanitize_ident($_) } @{$args->{insert_cols}}) . ') '
        . "FROM STDIN WITH CSV";
}

sub _statement_upsert {
    my ($args) = @_;
    for (qw(insert_cols update_cols key_cols table tempname)) {
        croak "Missing argument $_" unless $args->{$_};
    }
    my $table = _sanitize_ident($args->{table});
    my $temp  = _sanitize_ident($args->{tempname});

    return "WITH UP AS (
     UPDATE $table
        SET " . join(
        ",
            ", map { _sanitize_ident($_) . ' = ' . "$temp." . _sanitize_ident($_) } @{$args->{update_cols}})
        . "
       FROM $temp
      WHERE " . join("
            AND ", map { "$table." . _sanitize_ident($_) . ' = ' . "$temp." . _sanitize_ident($_) } @{$args->{key_cols}}) . "
 RETURNING " . join(", ", map { "$table." . _sanitize_ident($_) } @{$args->{key_cols}}) . "
)
    INSERT INTO $table (" . join(", ", map { _sanitize_ident($_) } @{$args->{insert_cols}}) . ")
    SELECT " . join(", ", map { _sanitize_ident($_) } @{$args->{insert_cols}}) . "
      FROM $temp
     WHERE ROW(" . join(", ", map { "$temp." . _sanitize_ident($_) } @{$args->{key_cols}}) . ")
           NOT IN (SELECT " . join(", ", map { "UP." . _sanitize_ident($_) } @{$args->{key_cols}}) . " FROM UP)";

}

sub statement {
    my %args = @_;
    croak "Missing argument 'type'" unless $args{type};
    no strict 'refs';
    return &{"_statement_$args{type}"}(\%args);
}

=head2 upsert

Creates a temporary table named "pg_object.bulkload" and copies the data there

If the first argument is an object, then if there is a function by the name
of the object, it will provide the value.

=over

=item table

Table to upsert into

=item insert_cols

Columns to insert (by name)

=item update_cols

Columns to update (by name)

=item key_cols

Key columns (by name)

=item group_stats_by

This is an array of column names for optional stats retrieval and grouping.
If it is set then we will grab the stats and return them.  Note this has a
performance penalty because it means an extra scan of the temp table and an
extra join against the parent table.  See get_stats for the return value
information if this is set.

=back

=cut

sub _build_args {
    my ($init_args, $obj) = @_;
    my @arglist = qw(table insert_cols update_cols key_cols dbh
        tempname group_stats_by);
    return {
        map {
            my $val;
            for my $v ($init_args->{$_}, try { $obj->$_ }) {
                $val = $v if defined $v;
            }
            $_ => $val;
        } @arglist
    };
}

sub upsert {    ## no critic (ArgUnpacking)
    my ($args) = shift;
    $args = shift if $args eq __PACKAGE__;
    try {
        $args->can('foo');
        unshift @_, $args;    # args is an object
    };
    $args = _build_args($args, $_[0]);
    my $dbh = $args->{dbh};

    # pg_temp is the schema of temporary tables.  If someone wants to create
    # a permanent table there, they are inviting disaster.  At any rate this is
    # safe but a plain drop without schema qualification risks losing user data.

    my $return_value;

    $dbh->do("DROP TABLE IF EXISTS pg_temp.pgobject_bulkloader");
    $dbh->do(
        statement(
            %$args,
            (
                type     => 'temp',
                tempname => 'pgobject_bulkloader'
            )));
    copy({(%$args, (table => 'pgobject_bulkloader'))}, @_);

    if ($args->{group_stats_by}) {
        $return_value = get_stats({(%$args, (tempname => 'pgobject_bulkloader'))});
    }

    $dbh->do(
        statement(
            %$args,
            (
                type     => 'upsert',
                tempname => 'pgobject_bulkloader'
            )));
    my $dropstatus = $dbh->do("DROP TABLE pg_temp.pgobject_bulkloader");
    return $return_value if $args->{group_stats_by};
    return $dropstatus;
}

=head2 copy

Copies data into the specified table.  The following arguments are used:

=over

=item table

Table to upsert into

=item insert_cols

Columns to insert (by name)

=back

=cut

sub _to_csv {
    my ($args) = shift;

    my $csv = Text::CSV->new();
    return join(
        "\n",
        map {
            my $obj = $_;
            $csv->combine(map { $obj->{$_} } @{$args->{cols}});
            $csv->string();
        } @_
    );
}

sub copy {    ## no critic (ArgUnpacking)
    my ($args) = shift;
    $args = shift if $args eq __PACKAGE__;
    try {
        no warnings;    ## no critic (ProhibitNoWarnings)
        no strict;      ## no critic (ProhibitNoStrict)
        $args->can('foo');
        unshift @_, $args;    # args is an object
    };
    $args = _build_args($args, $_[0]);
    my $dbh = $args->{dbh};
    $dbh->do(statement(%$args, (type => 'copy')));
    $dbh->pg_putcopydata(_to_csv({cols => $args->{insert_cols}}, @_));
    return $dbh->pg_putcopyend();
}

=head2 get_stats

Takes the same arguments as upsert plus group_stats_by

Returns an array of hashrefs representing the number of inserts and updates
that an upsert will perform.  It must be performed before the upsert statement
actually runs.  Typically this is run via the upsert command (which
automatically runs this if group_stats_by is set in the argumements hash).

There is a performance penalty here since an unindexed left join is required
between the temp and the normal table.

This function requires tempname, table, and group_stats_by to be set in the
argument hashref.  The return value is a list of hashrefs with the following
keys:

=over

=item stats

Hashref with keys inserts and updates including numbers of rows.

=item keys

Hashref for key columns and their values, by name

=back

=cut

sub get_stats {    ## no critic (ArgUnpacking)
    my ($args) = shift;
    $args = shift if $args eq __PACKAGE__;
    try {
        no warnings;    ## no critic (ProhibitNoWarnings)
        no strict;      ## no critic (ProhibitNoStrict)
        $args->can('foo');
        unshift @_, $args;    # args is an object
    };
    $args = _build_args($args, $_[0]);
    my $dbh = $args->{dbh};

    return [
        map {
            my @row = @$_;
            {
                stats => {
                    updates => pop @row,
                    inserts => pop @row,
                },
                keys => {map { $_ => shift @row } @{$args->{group_stats_by}}},
            }
        } @{$dbh->selectall_arrayref(statement(%$args, (type => 'stats')))}];
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 CO-MAINTAINERS

=over

=item Binary.com, C<< <perl at binary.com> >>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-bulkupload at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-BulkLoad>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::BulkLoad


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-BulkLoad>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-BulkLoad>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-BulkLoad>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-BulkLoad/>

=back


=head1 ACKNOWLEDGEMENTS



=cut

1;    # End of PGObject::Util::BulkUpload
