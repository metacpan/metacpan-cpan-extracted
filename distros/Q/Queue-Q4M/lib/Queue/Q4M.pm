# $Id: /mirror/coderepos/lang/perl/Queue-Q4M/trunk/lib/Queue/Q4M.pm 103794 2009-04-13T11:38:30.159603Z daisuke  $
#
# Copyright (c) 2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Queue::Q4M;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Carp();
use DBI;
use SQL::Abstract;
use Queue::Q4M::Status;

class_type 'Queue::Q4M::Result';

has 'auto_reconnect' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 1,
);

has 'owner_mode' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

has '_connect_pid' => (
    is => 'rw',
    isa => 'Int'
);

has 'connect_info' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
);

has 'sql_maker' => (
    is => 'rw',
    isa => 'SQL::Abstract',
    required => 1,
    default  => sub { SQL::Abstract->new }
);

has '_dbh' => (
    is => 'rw',
);

has '__table' => (
    is => 'rw',
);

has '__res' => (
    is => 'rw',
#    isa => 'Maybe[Queue::Q4M::Result]'
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Any::Moose '::Util::TypeConstraints';

our $AUTHORITY = 'cpan:DMAKI';
our $VERSION   = '0.00019';

use constant Q4M_MINIMUM_VERSION => '0.8';

sub connect
{
    my $self = shift;
    if (! ref $self) {
        $self = $self->new(@_);
    }

    if (my $old = $self->_dbh()) {
        $old->disconnect();
    }

    my $dbh = $self->_connect();
    $self->_dbh( $dbh );

    # Make sure we have the minimum supported API version
    # (or, a Q4M enabled mysql, for that matter)
    my $version;
    eval {
        my $sth = $dbh->prepare(<<'        EOSQL');
            SELECT PLUGIN_VERSION from 
                information_schema.plugins
            WHERE plugin_name = ?
        EOSQL
        $sth->execute('QUEUE');
        $sth->bind_columns(\$version);
        $sth->fetchrow_arrayref;
        $sth->finish;
    };
    warn if $@;

    if (! $version || $version < Q4M_MINIMUM_VERSION) {
        Carp::confess( "Connected database does not meet the minimum required q4m version (" . Q4M_MINIMUM_VERSION . "). Got version " . (defined $version ? $version : '(undef)'  ) );
    }

    $self;
}

sub _connect
{
    my $self = shift;

    return DBI->connect(@{ $self->connect_info });
}

sub dbh
{
    my $self = shift;
    my $dbh = $self->_dbh;

    my $pid = $self->_connect_pid;
    if ( ($pid || '') ne $$ || ! $dbh || ! $dbh->ping) {
        $self->auto_reconnect or die "not connect";
        $dbh = $self->_connect();
        $self->_dbh( $dbh );
        $self->_connect_pid($$);
    }
    return $dbh;
}

sub next
{
    my $self = shift;
    my @args = @_;

    # First, undef any cached table name that we might have had
    $self->__table(undef);

    my @tables = 
        grep { !/^\d+$/ }
        map  {
            (my $v = $_) =~ s/:.*$//;
            $v
        }
        @args
    ;

    # Cache this statement handler so we don't unnecessarily create
    # string or handles
    my $dbh = $self->dbh;
    my $sql = sprintf(
        "SELECT queue_wait(%s)",
        join(',', (('?') x scalar(@args)))
    );
    my ($index) = $dbh->selectrow_array($sql, undef, @args);

    my $table = defined $index && $index > 0 ? $tables[$index - 1] : undef;
    my $res = Queue::Q4M::Result->new(
        rv         => defined $table,
        table      => $table,
        on_release => sub { $self->__table(undef) }
    );

    if (defined $table) {
        $self->__table($table);
    }
    $self->__res($res) if $res;
    $self->owner_mode(1);
    return $res;
}

*fetch = \&fetch_array;

BEGIN
{
    foreach my $type qw(array arrayref hashref) {
        eval sprintf( <<'EOSUB', $type, $type );
            sub fetch_%s {
                my $self = shift;
                my $table = shift;
                $table ||= $self->__table;
                if (Scalar::Util::blessed $table &&
                    $table->isa('Queue::Q4M::Result'))
                {
                    $table = $table->[1];
                }

                $table or die "no table";

                my ($sql, @bind) = $self->sql_maker->select($table, @_);
                my $dbh = $self->dbh;
                $self->owner_mode(0);
                return $dbh->selectrow_%s($sql, undef, @bind);
            }
EOSUB
        die if $@;
    }
}

sub insert
{
    my $self  = shift;
    my $table = shift;

    my ($sql, @bind) = $self->sql_maker->insert($table, @_);
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare($sql);
    my $rv = $sth->execute(@bind);
    $sth->finish;
    return $rv;
}

sub disconnect
{
    my $self = shift;
    my $dbh  = $self->dbh;
    if ($dbh) {
        $dbh->do("select queue_end()");
        $dbh->disconnect;
        $self->_dbh(undef);
    }
}

sub clear
{
    my ($self, $table) = @_;
    return $self->dbh->do("DELETE FROM $table");
}

sub status {
    return Queue::Q4M::Status->fetch( shift->dbh );
}

sub DEMOLISH
{
    my $self = shift;
    local $@;
    eval {
        $self->dbh->do("SELECT queue_abort()") if $self->owner_mode;
        $self->disconnect;
    };
}

package
    Queue::Q4M::Result;
use overload
    bool => \&as_bool,
    '""' => \&as_string,
    fallback => 1
;
use Scope::Guard;

sub new
{
    my $class = shift;
    my %args  = @_;
    return bless [ $args{rv}, $args{table}, Scope::Guard->new( $args{on_release} ) ], $class;
}

sub as_bool { $_[0]->[0] }
sub as_string { $_[0]->[1] }
sub DESTROY { $_[0]->[2]->dismiss(1) if $_[0]->[2] }

1;

__END__

=head1 NAME

Queue::Q4M - Simple Interface To q4m

=head1 SYNOPSIS

  use Queue::Q4M;

  my $q = Queue::Q4M->connect(
    connect_info => [
      'dbi:mysql:dbname=mydb',
      $username,
      $password
    ],
  );

  for (1..10) {
    $q->insert($table, \%fieldvals);
  }

  while ($q->next($table)) {
    my ($col1, $col2, $col3) = $q->fetch($table, \@fields);
    print "col1 = $col1, col2 = $col2, col3 = $col3\n";
  }

  while ($q->next($table)) {
    my $cols = $q->fetch_arrayref($table, \@fields);
    print "col1 = $cols->[0], col2 = $cols->[1], col3 = $cols->[2]\n";
  }

  while ($q->next($table)) {
    my $cols = $q->fetch_hashref($table, \@fields);
    print "col1 = $cols->{col1}, col2 = $cols->{col2}, col3 = $cols->{col3}\n";
  }

  # to use queue_wait(table_cond1,table_cond2,timeout)
  while (my $which = $q->next(@table_conds)) {
    # $which contains the table name
  }

  $q->disconnect;

=head1 DESCRIPTION

Queue::Q4M is a simple wrapper to q4m, which is an implementation of a queue
using mysql.

=head1 METHODS

=head2 new

Creates a new Queue::Q4M instance. Normally you should use connect() instead.

=head2 connect

Connects to the target database.

  my $q = Queue::Q4M->connect(
    connect_info => [
      'dbi:mysql:dbname=q4m',
    ]
  );

=head2 next($table_cond1[, $table_cond2, $table_cond3, ..., $timeout])

Blocks until the next item is available. This is equivalent to calling
queue_wait() on the given table.

  my $which = $q->next( $table_cond1, $table_cond2, $table_cond3 );

=head2 fetch

=head2 fetch_array

Fetches the next available row. Takes a table name and the list of columns to be fetched.

  my ($col1, $col2, $col3) = $q->fetch( $table, [ qw(col1 col2 col3) ] );

=head2 fetch_arrayref

Same as fetch_array, but fetches using fetchrow_arrayref()

  my $arrayref = $q->fetch_arrayref( $table, [ qw(col1 col2 col3) ] );

=head2 fetch_hashref

Same as fetch_array, but fetches using fetchrow_hashref()

  my $hashref = $q->fetch_hashref( $table, [ qw(col1 col2 col3) ] );

=head2 insert($table, \%field)

Inserts into the queue. The first argument should be a scalar specifying
a table name. The second argument is a hashref that specifies the mapping
between column names and their respective values.

  $q->insert($table, { col1 => $val1, col2 => $val2, col3 => $val3 });

For backwards compatibility, you may omit $table if you specified $table
in the constructor.

=head2 clear($table)

Deletes everything the specified queue. Be careful!

=head2 status()

Returns an instance of Queue::Q4M::Status (actually, a subclass there of).

=head2 dbh

Returns the database handle after making sure that it's connected.

=head2 disconnect

Disconnects.

=head2 BUILD

=head2 DEMOLISH

These are defined as part of Moose infrastructure

=head2 Q4M_MINIMUM_VERSION

The minimum version of q4m that Queue::Q4M supports

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 CONTRIBUTOR

Taro Funaki 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
