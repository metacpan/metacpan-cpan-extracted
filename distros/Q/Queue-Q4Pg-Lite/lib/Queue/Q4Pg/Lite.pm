package Queue::Q4Pg::Lite;

use strict;
use warnings;
our $VERSION = '0.03';

use Carp ();
use Any::Moose;
use DBI;
use SQL::Abstract;

has 'auto_reconnect' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has 'connect_info' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
);

has 'sql_maker' => (
    is       => 'rw',
    isa      => 'SQL::Abstract',
    required => 1,
    default  => sub { SQL::Abstract->new }
);

has '_dbh' => (
    is => 'rw',
);

has '_res' => (
    is  => 'rw',
);

has 'interval' => (
    is      => 'rw',
    isa     => 'Int',
    default => 5,
);

use constant PG_ADVISORY_LOCK_SUPPORT_VERSION => 80200;

no Any::Moose;

sub connect {
    my $self = shift;
    if (! ref $self) {
        $self = $self->new(@_);
    }

    if (my $old = $self->_dbh()) {
        $old->disconnect();
    }

    my $dbh = $self->_connect();
    $self->_dbh( $dbh );

    my $version = $dbh->{pg_server_version};
    if ( $version < PG_ADVISORY_LOCK_SUPPORT_VERSION ) {
        Carp::confess( "Connected database does not support pg_advisory_lock(). required PostgreSQL version (" . PG_ADVISORY_LOCK_SUPPORT_VERSION . "). Got version " . (defined $version ? $version : '(undef)'  ) );
    }
    $self;
}

sub _connect {
    my $self = shift;

    return DBI->connect(@{ $self->connect_info });
}

sub dbh {
    my $self = shift;
    my $dbh = $self->_dbh;

    if ( ! $dbh || ! $dbh->ping ) {
        $self->auto_reconnect or die "not connect";
        $dbh = $self->_connect();
        $self->_dbh( $dbh );
    }
    return $dbh;
}

sub next {
    my $self  = shift;
    my $table = shift;
    my ( $where ) = @_;

    if ( my $pre = $self->_res ) {
        Carp::carp( 'abort not finished job. id='. $pre->{id} );
        $self->abort;
    }
    my $dbh = $self->dbh;
    my $sql = "SELECT * FROM $table";
    my ($sql_where, @bind) = $self->sql_maker->where($where);
    if ( $sql_where eq '' ) {
        $sql .= " WHERE pg_try_advisory_lock(tableoid::int, id)";
    }
    else {
        (my $cond = $sql_where) =~ s/^\s+WHERE\s//i;
        $sql .= " WHERE CASE WHEN $cond THEN pg_try_advisory_lock(tableoid::int, id) ELSE false END";
    }
    $sql .= " LIMIT 1";

    my $sth = $dbh->prepare($sql);

    while ( $sth->execute(@bind) ) {
        my $res = $sth->fetchrow_hashref;
        if ($res) {
            $res->{_table} = $table;
            $self->_res($res);
            return $res;
        }
        sleep $self->interval;
    }
    return;
}

*fetch = \&fetch_hashref;

sub fetch_hashref {
    my $self = shift;
    return $self->_res;
}

sub abort {
    my $self = shift;

    return unless $self->_res;

    my $dbh  = $self->_dbh;
    my $res  = $self->_res;
    my $sql
        = "SELECT pg_advisory_unlock(tableoid::int, ?) FROM "
        . $res->{_table};
    my $sth  = $dbh->prepare($sql);
    $sth->execute( $res->{id} );
    my $r = $sth->fetchrow_arrayref;
    $sth->finish;
    return $r->[0];
}

sub ack {
    my $self = shift;

    return unless $self->_res;

    my $dbh  = $self->_dbh;
    my $res  = $self->_res;

    my ($sql, @bind) = $self->sql_maker->delete(
        $res->{_table},
        { id => $res->{id} },
    );
    $sql .= " RETURNING pg_advisory_unlock(tableoid::int, id)";
    my $sth  = $dbh->prepare($sql);
    $sth->execute(@bind);
    my $r = $sth->fetchrow_arrayref;
    $sth->finish;

    $self->_res(undef);
    return $r->[0];
}

sub insert {
    my $self  = shift;
    my $table = shift;

    my ($sql, @bind) = $self->sql_maker->insert($table, @_);
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare($sql);
    my $rv = $sth->execute(@bind);
    $sth->finish;
    return $rv;
}

sub disconnect {
    my $self = shift;
    $self->_dbh->disconnect if $self->_dbh;
    $self->_dbh(undef);
    $self->_res(undef);
    1;
}

sub clear {
    my $self = shift;
    my $table = shift;
    my ($sql, @bind) = $self->sql_maker->delete(
        $table,
        { "pg_try_advisory_lock(tableoid::int, id)" => \"" },
    );
    $sql .= " RETURNING pg_advisory_unlock(tableoid::int, id)";
    my $sth  = $self->dbh->prepare($sql);
    my $rows = $sth->execute();
    $sth->finish();
    return $rows;
}

sub DESTROY {
    my $self = shift;
    $self->abort if $self->_res;
    $self->disconnect;
}

1;
__END__

=head1 NAME

Queue::Q4Pg::Lite - Simple message queue using PostgreSQL

=head1 SYNOPSIS

  use Queue::Q4Pg::Lite;

  my $q = Queue::Q4Pg::Lite->connect(
    connect_info => [
      'dbi:Pg:dbname=mydb',
      $username,
      $password
    ],
  );

  for (1..10) {
    $q->insert($table, \%fieldvals);
  }

  while ($q->next($table)) {
    my $cols = $q->fetch_hashref()
    print "col1 = $cols->{col1}, col2 = $cols->{col2}, col3 = $cols->{col3}\n";
    $q->ack;
  }

  $q->disconnect;

  # Table schema requires id column.
  CREATE TABLE mq ( id SERIAL PRIMARY KEY, message TEXT );

=head1 DESCRIPTION

Queue::Q4Pg::Lite is a simple message queue using PostgreSQL which supports pg_advisory_lock (version 8.2 or later).

This algorithms was invented by http://d.hatena.ne.jp/n_shuyo/20090415/mq .

Many codes copied from L<Queue::Q4M>.

=head1 METHODS

=head2 new

Creates a new Queue::Q4Pg::Lite instance. Normally you should use connect() instead.

=head2 connect

Connects to the target database.

  my $q = Queue::Q4Pg::Lite->connect(
    connect_info => [
      'dbi:Pg:dbname=q4pg',
    ]
  );

=head2 next($table, [$where]);

Blocks until the next item is available.

$where is same of arguments for L<SQL::Abstract>->select($table, $col, $where)

  # SELECT * FROM mq WHERE priority < 10;
  $q->next("mq", { priority => { "<", 10 } });

=head2 fetch_hashref

Fetches the next available row as hashref.

  my $hashref = $q->fetch_hashref();

=head2 ack

Delete the fetched row from table.

If You don't call ack(), the fetched row is not deleted from table.

=head2 insert($table, \%field)

Inserts into the queue. The first argument should be a scalar specifying
a table name. The second argument is a hashref that specifies the mapping
between column names and their respective values.

  $q->insert($table, { col1 => $val1, col2 => $val2, col3 => $val3 });

=head2 clear($table);

Deletes everything the specified queue.

=head2 dbh

Returns the database handle after making sure that it's connected.

=head2 disconnect

Disconnects.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara@cpan.orgE<gt>

=head1 SEE ALSO

L<Queue::Q4M>, L<SQL::Abstract>, http://d.hatena.ne.jp/n_shuyo/20090415/mq

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
