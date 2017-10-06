package ObjectDB::DBHPool;

use strict;
use warnings;

our $VERSION = '3.24';

require Carp;
use ObjectDB::DBHPool::Connection;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{check_timeout} = $params{check_timeout};
    $self->{dsn}           = $params{dsn};
    $self->{username}      = $params{username};
    $self->{password}      = $params{password};
    $self->{attrs}         = $params{attrs};
    $self->{do}            = $params{do};

    $self->{connections} = {};

    return $self;
}

sub dbh {
    my $self = shift;

    # From DBIx::Connector
    my $pid_tid = $$;
    $pid_tid .= '_' . threads->tid
      if exists $INC{'threads.pm'} && $INC{'threads.pm'};

    my $connection = $self->{connections}->{$pid_tid} ||= ObjectDB::DBHPool::Connection->new(
        check_timeout => $self->{check_timeout},
        dsn           => $self->{dsn},
        username      => $self->{username},
        password      => $self->{password},
        attrs         => $self->{attrs},
        do            => $self->{do},
    );

    return $connection->dbh;
}

1;
