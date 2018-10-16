package ObjectDB::DBHPool::Connection;

use strict;
use warnings;

our $VERSION = '3.28';

require Carp;
use DBI;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {@_};
    bless $self, $class;

    $self->{check_timeout} = $params{check_timeout};
    $self->{dsn}           = $params{dsn};
    $self->{username}      = $params{username};
    $self->{password}      = $params{password};
    $self->{attrs}         = $params{attrs};
    $self->{do}            = $params{do};

    $self->{check_timeout} = 5 unless defined $self->{check_timeout};
    $self->{attrs} ||= { RaiseError => 1 };

    return $self;
}

sub dbh {
    my $self = shift;

    if (!$self->{dbh}) {
        $self->_connect;
    }
    elsif (!$self->_check_connection) {
        $self->_reconnect;
    }

    return $self->{dbh};
}

sub _connect {
    my $self = shift;

    $self->{dbh}        = $self->_get_dbh;
    $self->{last_check} = time;

    return $self->{dbh};
}

sub _reconnect {
    my $self = shift;

    eval { $self->{dbh}->disconnect };

    return $self->_connect;
}

sub _check_connection {
    my $self = shift;

    return 1 unless $self->_is_check_needed;

    $self->{last_check} = time;

    my $dbh = $self->{dbh};

    return unless $dbh && $dbh->{Active};

    return 1 if int $dbh->ping;

    return eval { $dbh->do('select 1'); 1; };
}

sub _is_check_needed {
    my $self = shift;

    return 1 if !$self->{dbh}->{Active} || $self->_is_check_timeout_elapsed;

    return 0;
}

sub _is_check_timeout_elapsed {
    my $self = shift;

    if ($self->{check_timeout}
        && time - $self->{last_check} > $self->{check_timeout})
    {
        return 1;
    }

    return 0;
}

sub _get_dbh {
    my $self = shift;

    my $dbh = DBI->connect($self->{dsn}, $self->{username}, $self->{password}, $self->{attrs});

    Carp::croak("Can't connect $DBI::errstr") unless $dbh;

    if ($self->{do}) {
        foreach my $do (ref $self->{do} eq 'ARRAY' ? @{ $self->{do} } : ($self->{do})) {
            $dbh->do($do);
        }
    }

    return $dbh;
}

1;
