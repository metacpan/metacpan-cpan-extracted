package Pinwheel::Database::Base;

use strict;
use warnings;

use DBI;

sub new
{
    my $class = shift;
    my $self = {
        dbh => undef,
        dbconfig => \@_,
        connect_time => 0,
        dbh_checked => 0,
        dbhostname => undef,
        prepared => {},
        orphans => [],
    };
    return bless($self, $class);
}


sub connect
{
    my ($dbh_age, $reconnect);
    my $self = shift;

    $dbh_age = time() - ($self->{connect_time} || 0);
    if (!$self->{dbh} || !$self->{dbh}->ping) {
        $reconnect = 1;
    } elsif ($dbh_age >= 300) {
        finish_all();
        $self->{dbh}->disconnect;
        $self->{dbhostname} = undef;
        $reconnect = 1;
    } else {
        $reconnect = 0;
    }

    if ($reconnect) {
        $self->{prepared} = {};
        $self->{orphans} = [];
        $self->{dbh} = DBI->connect(@{$self->{dbconfig}});
        $self->{dbh}->{unicode} = 1;
        $self->{connect_time} = time();
        $self->{ping_time} = time();
    }
    
    # We have now checked that we are connected
    $self->{dbh_checked} = 1;
}

sub disconnect
{
    my $self = shift;
    if ($self->{dbh}) {
        $self->finish_all();
        $self->{dbh}->disconnect;
        $self->{dbh} = undef;
        $self->{dbh_checked} = 0;
        $self->{dbhostname} = undef;
    }
}

sub do
{
    my $self = shift;
    $self->connect() if (!$self->{dbh} || !$self->{dbh_checked});
    return $self->{dbh}->do(@_);
}

sub describe
{
    warn "Database specific sub-classes should redefine this method";
    return undef;
}

sub tables
{
    warn "Database specific sub-classes should redefine this method";
    return undef;
}

sub without_foreign_keys
{
    ## Database specific sub-classes should redefine this method if required
    my ($self, $block) = @_;
    &$block();
}

sub dbhostname
{
    return $_[0]->{dbhostname};
}

sub prepare
{
    my ($self, $query, $transient) = @_;
    my $sth;

    $self->connect() if (!$self->{dbh} || !$self->{dbh_checked});

    $sth = $self->{prepared}->{$query};
    if ($sth) {
        return $sth unless $sth->{Active};
        push(@{$self->{orphans}}, $sth);
    }

    $sth = $self->{dbh}->prepare($query);
    $self->{prepared}->{$query} = $sth unless $transient;
    return $sth;
}

sub selectcol_array
{
    my ($self, $statement) = @_;
    my $sth = $self->prepare($statement);
    $sth->execute();
    my @result = ();
    while (my ($col) = $sth->fetchrow_array()) {
        push(@result, $col);
    }
    return @result;
}

sub finish_all
{
    my $self = shift;
    foreach my $sth (values(%{$self->{prepared}})) {
        $sth->finish() if ($sth->{Active});
    }
    foreach my $sth (@{$self->{orphans}}) {
        $sth->finish() if ($sth->{Active});
    }
    $self->{orphans} = [];
    $self->{dbh_checked} = 0;   # The database connection needs re-checking
}

sub fetchone_tables
{
    my ($self, $sth, $tables) = @_;
    my ($slices, $row);

    if (!$tables || scalar(@$tables) == 0) {
        $row = $sth->fetchrow_hashref();
        return undef unless $row;
        return { '' => $row };
    }

    $slices = _get_column_slices($sth);
    $row = $sth->fetchrow_arrayref();
    return undef unless $row;
    return _extract_table_data($slices, $tables, $row);
}

sub fetchall_tables
{
    my ($self, $sth, $tables) = @_;

    if (!$tables || scalar(@$tables) == 0) {
        my @result = map { { '' => $_ } } @{$sth->fetchall_arrayref({})};
        return \@result;
    }

    my (@result, $slices, $row);
    $slices = _get_column_slices($sth);
    while ($row = $sth->fetchrow_arrayref()) {
        push @result, _extract_table_data($slices, $tables, $row);
    }
    return \@result;
}

sub _get_column_slices
{
    my $sth = shift;
    my ($columns, @slices, $i, $j);

    $columns = $sth->{NAME_lc};
    for ($i = 0, $j = 0; $j <= @$columns; $j++) {
        if ($j == @$columns || ($j > 0 && $columns->[$j] eq 'id')) {
            my @slice = ($i .. $j - 1);
            push @slices, [[@$columns[@slice]], \@slice];
            $i = $j;
        }
    }

    return \@slices;
}

sub _extract_table_data
{
    my ($slices, $tables, $row) = @_;
    my (%result, $i, $name, $keys, $slice);

    $i = 0;
    $name = '';
    do {
        my %data;
        ($keys, $slice) = @{$slices->[$i]};
        @data{@$keys} = @$row[@$slice];
        $result{$name} = \%data;
    } while ($name = $tables->[$i++]);

    return \%result;
}

1;

__DATA__

=head1 NAME

Pinwheel::Database::Base

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

