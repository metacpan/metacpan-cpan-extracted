package Spreadsheet::Compare::Reader::DB;

use Mojo::Base 'Spreadsheet::Compare::Reader', -signatures;
use Spreadsheet::Compare::Common;

#<<<
use Spreadsheet::Compare::Config {
    column_case => undef,
    dsns        => sub {[]},
    sql         => sub {[]},
}, make_attributes => 1;

use DBI;

has has_header => 1,     ro  => 1;
has dbh        => undef, ro  => 1;
has _sth       => undef, ro  => 1;
#>>>

my( $trace, $debug );

sub setup ($self) {
    ( $trace, $debug ) = get_log_settings();

    my $cfg = $self->dsns->$#* ? $self->dsns->[ $self->index ] : $self->dsns->[0];
    LOGDIE "no DSN configured" unless $cfg;
    INFO "connecting to >>$cfg->{dsn}<<";

    my $dbh = DBI->connect(
        $cfg->{dsn},
        $cfg->{usr} // '',
        $cfg->{pwd} // '', {
            RaiseError => 1,
            ChopBlanks => 1,
        },
    );
    $self->{__ro__dbh} = $dbh;

    my $stmt = $self->sql->$#* ? $self->sql->[ $self->{index} ] : $self->sql->[0];
    LOGDIE "no sql statement configured" unless $stmt;

    $debug and DEBUG "preparing sql statement, '$stmt'";
    $self->{__ro___sth} = my $sth = $dbh->prepare($stmt);

    $debug and DEBUG "executing sql statement";
    $sth->execute();

    $self->{_cattr}       = $self->column_case ? 'NAME_' . $self->column_case : 'NAME';
    $self->{__ro__header} = $sth->{ $self->{_cattr} };

    return $self;
}


sub fetch ( $self, $size ) {

    $debug and DEBUG "fetching $size records";

    my $result  = $self->result;
    my $skipper = $self->skipper;
    my $sth     = $self->_sth;
    my $i       = 0;
    while ( ++$i <= $size ) {
        my @rec = $sth->fetchrow_array;
        $trace and TRACE "fetched db record:", sub { Dump( \@rec ) };
        unless (@rec) {
            $self->{__ro__exhausted} = 1;
            last;
        }
        my $robj = Spreadsheet::Compare::Record->new(
            rec    => \@rec,
            reader => $self,
        );
        next if $skipper and $skipper->($robj);
        push @$result, $robj;
    }

    my $count = @$result;

    $debug and DEBUG "fetched $count records";

    return $count;
}


sub DESTROY ($self) {
    $self->_sth->finish    if $self->_sth;
    $self->dbh->disconnect if $self->dbh;
    return;
}


1;

=head1 NAME

Spreadsheet::Compare::Reader::DB - Database Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

This module provides an init/fetch interface for records returned from a database query

=head1 EXAMPLE

    ---
    - title: __GLOBAL__
      type: DB
      dsns :
        - dsn: 'dbi:SQLite:dbname=t/left/db.sqlite'
        - dsn: 'dbi:SQLite:dbname=t/right/db.sqlite'
    #=============================================
    - title     : default config
      sql :
        - select * from table01
      identity: '[ROW_ID]'
    #=============================================
    - title     : construct id upper case column names
      sql :
        - select
            *,
            type || color as 'id'
          from table02
      identity: '[ID]'
      column_case: uc

=head1 ATTRIBUTES

L<Spreadsheet::Compare::Reader::DB> implements the following attributes.

=head2 column_case

  possible values: <lc|uc|undef>
  default: undef

The DBI method for converting header name case. Default is using the header as is.
Use 'uc' to use upper case header names and 'lc' for lower case.

=head2 dbh

(B<readonly>) returns the current DBI database handle.

=head2 dsns

  possible values: <list of one or two hashes>
  default: []

Example:

  dsns:
    - dsn: 'dbi:SQLite:dbname=./left/db.sqlite'
    - dsn: 'dbi:SQLite:dbname=./right/db.sqlite'

A list of one or two hashes defining a database connection. If only one
definition is used, the comparison will be run on the same database and you will need
two different sql statements for the L</sql> option.

An entry has to be a hash with the keys 'dsn', 'usr' and 'pwd'. Only 'dsn' is mandatory.
The dsn can be any valid Perl DBI DSN.

=head2 has_header

(B<readonly>) always true. The column names from the SQL statements are used.

=head2 sql

Example:

  sql :
    - select * from left_table order by id
    - select * from right_table order by id

A list of one or two sql statements extracting the data to be compared.
If only one statement is issued it will be used for both sides of the
comparison. In this case two different L</dsns> should be used.

It is advisable to construct an identity column in the statement and use this for
L<Spreadsheet::Compare::Reader/identity>. This is faster than using an identity
consisting of multiple columns.

For very large data sets, memory consumption can be limited by sorting the statement
results by that column with an 'order by' directive, setting the option
"is_sorted" (L<Spreadsheet::Compare::Single/is_sorted>) to a true value and use
"fetch_size" (L<Spreadsheet::Compare::Single/fetch:_size>) to limit the number of
records that will be compared in one batch. Also see (L<Spreadsheet::Compare/"MEMORY USAGE">).

=head1 METHODS

L<Spreadsheet::Compare::Reader::DB> inherits or overwrites all methods from L<Spreadsheet::Compare::Reader>.

=cut
