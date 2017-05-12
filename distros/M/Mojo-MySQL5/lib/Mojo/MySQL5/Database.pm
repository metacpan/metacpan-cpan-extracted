package Mojo::MySQL5::Database;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::MySQL5::Connection;
use Mojo::MySQL5::Results;
use Mojo::MySQL5::Transaction;
use Encode '_utf8_off';
use Scalar::Util 'weaken';
use Carp 'croak';

has ['mysql', 'connection'];

sub DESTROY {
  my $self = shift;
  return unless my $c = $self->connection;
  return unless my $mysql = $self->mysql;
  $mysql->_enqueue($c);
}

sub backlog { scalar @{shift->{waiting} || []} }

sub begin {
  my $self = shift;
  croak 'Already in a transaction' if ($self->connection->{status_flags} & 0x0001);
  $self->query('START TRANSACTION');
  $self->query('SET autocommit=0');
  my $tx = Mojo::MySQL5::Transaction->new(db => $self);
  weaken $tx->{db};
  return $tx;
}

sub connect {
  my $self = shift;
  my $c = Mojo::MySQL5::Connection->new(url => $self->mysql->url->clone);
  $c->on(error => sub {
    my ($c, $err) = @_;
    warn 'Unable to connect to "', $self->mysql->url, '" ', $err, "\n";
  });
  $c->connect();
  $c->unsubscribe('error');
  return $self->connection($c);
}

sub disconnect { shift->connection->disconnect }

sub pid { shift->connection->{connection_id} }

sub ping { shift->connection->ping }

sub query {
  my $self = shift;
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $sql = shift;
  my $expand_sql = '';

  _utf8_off $sql;

  while (length($sql) > 0) {
    my $token;
    if ($sql =~ /^(\s+)/s                                   # whitespace
      or $sql =~ /^(\w+)/) {                                # general name
      $token = $1;
    }
    elsif ($sql =~ /^--.*(?:\n|\z)/p                        # double-dash comment
      or $sql =~ /^\#.*(?:\n|\z)/p                          # hash comment
      or $sql =~ /^\/\*(?:[^\*]|\*[^\/])*(?:\*\/|\*\z|\z)/p # C-style comment
      or $sql =~ /^'(?:[^'\\]*|\\(?:.|\n)|'')*(?:'|\z)/p    # single-quoted literal text
      or $sql =~ /^"(?:[^"\\]*|\\(?:.|\n)|"")*(?:"|\z)/p    # double-quoted literal text
      or $sql =~ /^`(?:[^`]*|``)*(?:`|\z)/p) {              # schema-quoted literal text
      $token = ${^MATCH};
    }
    else {
      $token = substr($sql, 0, 1);
    }
    $expand_sql .= $token eq '?' ? $self->quote(shift) : $token;
    substr($sql, 0, length($token), '');
  }

  croak 'async query in flight' if $self->backlog and !$cb;
  $self->_subscribe unless $self->backlog;

  push @{$self->{waiting}}, { cb => $cb, sql => $expand_sql, count => 0, started => 0,
    results => Mojo::MySQL5::Results->new };

  # Blocking
  unless ($cb) {
    $self->connection->query($expand_sql);
    $self->_unsubscribe;
    my $current = shift @{$self->{waiting}};
    croak $self->connection->{error_message} if $self->connection->{error_code};
    return $current->{results};
  }

  # Non-blocking
  $self->_next;
}

sub quote {
  my ($self, $string) = @_;
  return 'NULL' unless defined $string;

  for ($string) {
    s/\\/\\\\/g;
    s/\0/\\0/g;
    s/\n/\\n/g;
    s/\r/\\r/g;
    s/'/\\'/g;
    # s/"/\\"/g;
    s/\x1a/\\Z/g;
  }

  return "'$string'";
}

sub quote_id {
  my ($self, $id) = @_;
  return 'NULL' unless defined $id;
  $id =~ s/`/``/g;
  return "`$id`";
}


sub _next {
  my $self = shift;

  return unless my $next = $self->{waiting}[0];
  return if $next->{started}++;

  $self->connection->query($next->{sql}, sub { 
    my $c = shift;
    my $current = shift @{$self->{waiting}};
    my $error = $c->{error_message};

    $self->backlog ? $self->_next : $self->_unsubscribe;

    my $cb = $current->{cb};
    $self->$cb($error, $current->{results});
  });

}

sub _subscribe {
  my $self = shift;

  $self->connection->on(fields => sub {
    my ($c, $fields) = @_;
    return unless my $res = $self->{waiting}->[0]->{results};
    push @{ $res->{_columns} }, $fields;
    $self->{waiting}->[0]->{count}++;
  });

  $self->connection->on(result => sub {
    my ($c, $row) = @_;
    return unless my $res = $self->{waiting}->[0]->{results};
    push @{ $res->{_results}->[$self->{waiting}->[0]->{count} - 1] //= [] }, $row;
  });

  $self->connection->on(end => sub {
    my $c = shift;
    return unless my $res = $self->{waiting}->[0]->{results};
    $res->{$_} = $c->{$_} for qw(affected_rows last_insert_id warnings_count);
  });

  $self->connection->on(error => sub {
    my $c = shift;
    return unless my $res = $self->{waiting}->[0]->{results};
    $res->{$_} = $c->{$_} for qw(error_code sql_state error_message);
  });
}

sub _unsubscribe {
  my $self = shift;
  $self->connection->unsubscribe($_) for qw(fields result end error);
}

1;

=encoding utf8

=head1 NAME

Mojo::MySQL5::Database - Database

=head1 SYNOPSIS

  use Mojo::MySQL5::Database;

  my $db = Mojo::MySQL5::Database->new(
    mysql => $mysql,
    connection => Mojo::MySQL5::Connection->new);

=head1 DESCRIPTION

L<Mojo::MySQL5::Database> is a container for L<Mojo::MySQL5::Connection> handles used by L<Mojo::MySQL5>.

=head1 ATTRIBUTES

L<Mojo::MySQL5::Database> implements the following attributes.

=head2 connection

  my $c = $db->connection;
  $db   = $db->connection(Mojo::MySQL5::Connection->new);

Database connection used for all queries.

=head2 mysql

L<Mojo::MySQL5> object this database belongs to.

=head1 METHODS

L<Mojo::MySQL5::Database> inherits all methods from L<Mojo::EventEmitter> and
implements the following ones.

=head2 backlog

  my $num = $db->backlog;

Number of waiting non-blocking queries.

=head2 begin

  my $tx = $db->begin;

Begin transaction and return L<Mojo::MySQL5::Transaction> object, which will
automatically roll back the transaction unless
L<Mojo::MySQL5::Transaction/"commit"> bas been called before it is destroyed.

  # Insert rows in a transaction
  eval {
    my $tx = $db->begin;
    $db->query('insert into frameworks values (?)', 'Catalyst');
    $db->query('insert into frameworks values (?)', 'Mojolicious');
    $tx->commit;
  };
  say $@ if $@;

=head2 connect

  $db->connect;

Connect to MySQL server.

=head2 disconnect

  $db->disconnect;

Disconnect database connection and prevent it from getting cached again.

=head2 pid

  my $pid = $db->pid;

Return the connection id of the backend server process.

=head2 ping

  my $bool = $db->ping;

Check database connection.

=head2 query

  my $results = $db->query('select * from foo');
  my $results = $db->query('insert into foo values (?, ?, ?)', @values);

Execute a blocking statement and return a L<Mojo::MySQL5::Results> object with the
results. You can also append a callback to perform operation non-blocking.

  $db->query('select * from foo' => sub {
    my ($db, $err, $results) = @_;
    ...
  });
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head2 quote
 
  my $escaped = $db->quote($str);
 
Quote string value for passing to SQL query.
 
=head2 quote_id
 
  my $escaped = $db->quote_id($id);
 
Quote identifier for passing to SQL query.

=head1 SEE ALSO

L<Mojo::MySQL5>.

=cut
