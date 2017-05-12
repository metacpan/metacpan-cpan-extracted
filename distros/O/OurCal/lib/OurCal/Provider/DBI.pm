package OurCal::Provider::DBI;

use strict;
use DBI;
use Carp qw(confess cluck);


=head1 NAME

OurCal::Provider::DBI -  a DBI provider for OurCal

=head1 SYNOPSIS

    [a_dbi_provider]
    dsn  = dbi:SQLite:ourcal
    type = dbi

=head1 CONFIG OPTIONS

=over 4 

=item dsn

A C<DBI> dsn. Required.

=item user

A user name. Optional.

=item pass

A password. Optional.

=back

=head1 METHODS

=cut

=head2 new <param[s]>

Requires an C<OurCal::Config> object as config param and a name param.

=cut

sub new {
    my $class  = shift;
    my %what   = @_;
    my $conf   = $what{config}->config($what{name});
    
    $what{dbh} = DBI->connect($conf->{dsn}, $conf->{user}, $conf->{pass}) 
        || die "Erk - couldn't connect to db $conf->{dsn}: $DBI::errstr\n";

    return bless \%what, $class;
}

sub events {
    my $self = shift;
    my %opts = @_;
    my ($sth,$sql)  = $self->_events(%opts);
    my @events;
    while (my $d = $sth->fetchrow_hashref()) {
        $d->{editable} = 1;
        my $e = OurCal::Event->new(%$d);
        push @events, $e;
    }
    return @events;
}

sub _events {
    my $self = shift;
    my %opts = @_;
    my $dbh  = $self->{dbh};

    my $what = ($opts{count})? "COUNT(*)" : "*";           

    my @vals; 
    my $sql  = "SELECT $what FROM events WHERE ";
    if (defined $opts{date}) {
        $sql .= " date=? AND";
        push @vals, $opts{date};
    }
    if (defined $opts{user}) {
        $sql .= " (user IS NULL OR user=?)";
        push @vals, $opts{user};
    } else {
        $sql .= " user IS NULL";
    }
    $sql .= " ORDER BY date DESC";
    if (defined $opts{limit}) {
        $sql .= " LIMIT ?";
        push @vals, $opts{limit};
    }

    #confess "Executing $sql with ".join(", ", @vals)."\n";
    my $sth  =  $dbh->prepare($sql);
    $sth->execute(@vals) || die $sth->errstr;
    return ($sth, $sql);
}

sub has_events {
    my $self = shift;
    my %opts = @_;
    die "Can't call has_events without a date\n" unless $opts{date};
    $opts{count} = 1;
    my ($sth) = $self->_events(%opts);
    my ($events) = $sth->fetchrow_array();
    return $events;
}


sub todos {
    my $self = shift;
    my %opts = @_;

    my $dbh  = $self->{dbh};

    my @vals;
    my $sql  = "SELECT * FROM todos WHERE user IS NULL";
    if (defined $opts{user}) {
        $sql .= " OR user=?";
        push @vals, $self->{user};
    }
    my $sth  =  $dbh->prepare($sql);
    $sth->execute(@vals) || die $sth->errstr;

    my @todos;
    while (my $d = $sth->fetchrow_hashref()) {
        my $t = OurCal::Todo->new(%$d);
        push @todos, $t;
    }
    return @todos;
}

sub users {
    my $self   = shift;
    my %opts   = shift;
    my $dbh    = $self->{dbh};
    my @tables = qw(todos events);
    my $sql    = join " UNION ", map { "SELECT user from $_ WHERE user IS NOT NULL" } @tables;
    my $sth    = $dbh->prepare($sql);
    $sth->execute() || die $sth->errstr;
    my @users;
    while (my $row = $sth->fetchrow_arrayref) {
        push @users, $row->[0];
    }
    return @users;
}

sub save_event {
    my $self  = shift;
    my $event = shift;
    my %opts  = @_;
    my $dbh   = $self->{dbh};
    
    # TODO we could check for id and do an update
    my $desc = $event->description;
    my $date = $event->date;
    my $sql;
    my @vals = ($date, $desc);
    if (defined $opts{user}) {
        $sql  = "INSERT INTO events (date, description, user) VALUES (?, ?, ?)";
        push @vals, $opts{user};
    } else {
        $sql  = "INSERT INTO events (date, description) VALUES (?, ?)";
    }

    my $sth  = $dbh->prepare($sql);
    $sth->execute(@vals) || die $sth->errstr;

}

sub del_event {
    my $self  = shift;
    my $event = shift;
    my %opts  = @_;
    my $dbh   = $self->{dbh};
    my $sql   = "DELETE FROM events WHERE id=?";
    my $sth   = $dbh->prepare($sql);
    $sth->execute($event->id) || die $sth->errstr;
}


sub save_todo {
    my $self  = shift;
    my $todo  = shift;
    my %opts  = @_;
    my $dbh   = $self->{dbh};
    
    # TODO we could check for id and do an update
    my $desc = $todo->full_description;
    my $sql;
    my @vals = ($desc);
    if (defined $opts{user}) {
        $sql  = "INSERT INTO todos (description, user) VALUES (?, ?, ?)";
        push @vals, $opts{user};
    } else {
        $sql  = "INSERT INTO todos (description) VALUES (?)";
    }

    use Carp qw(confess);
    my $sth  = $dbh->prepare($sql);
    $sth->execute(@vals) || die $sth->errstr;
}

sub del_todo {
    my $self  = shift;
    my $todo  = shift;
    my %opts  = @_;
    my $dbh   = $self->{dbh};
    my $sql   = "DELETE FROM todos WHERE id=?";
    my $sth   = $dbh->prepare($sql);
    $sth->execute($todo->id) || die $sth->errstr;
}

=head2 todos

Returns all the todos on the system.

=head2 has_events <param[s]>

Returns whether there are events given the params.

=head2 events <param[s]>

Returns all the events for the given params.

=head2 users

Returns the name of all the users on the system.

=head2 save_todo <OurCal::Todo>

Save a todo.

=head2 del_todo <OurCal::Todo>

Delete a todo.


=head2 save_event <OurCal::Event>

Save an event.

=head2 del_event <OurCal::Event>

Delete an event..

=cut



1;


