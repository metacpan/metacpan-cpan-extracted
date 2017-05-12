package Prancer::Plugin::Database::Driver;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.04';

use Try::Tiny;
use Carp;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub new {
    my ($class, $config, $connection) = @_;

    try {
        require DBI;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "could not initialize database connection '${connection}': could not load DBI: ${error}";
    };

    # this is the only required field
    unless ($config->{'database'}) {
        croak "could not initialize database connection '${connection}': no database name configured";
    }

    my $self = bless({}, $class);
    $self->{'_connection'}      = $connection;
    $self->{'_database'}        = $config->{'database'};
    $self->{'_username'}        = $config->{'username'};
    $self->{'_password'}        = $config->{'password'};
    $self->{'_hostname'}        = $config->{'hostname'};
    $self->{'_port'}            = $config->{'port'};
    $self->{'_autocommit'}      = $config->{'autocommit'};
    $self->{'_charset'}         = $config->{'charset'};
    $self->{'_check_threshold'} = $config->{'connection_check_threshold'} || 30;
    $self->{'_dsn_extra'}       = $config->{'dsn_extra'} || {};
    $self->{'_on_connect'}      = $config->{'on_connect'} || [];

    # store a pool of database connection handles
    $self->{'_handles'} = {};

    return $self;
}

sub handle {
    my $self = shift;

    # to be fork safe and thread safe, use a combination of the PID and TID (if
    # running with use threads) to make sure no two processes/threads share a
    # handle. implementation based on DBIx::Connector by David E. Wheeler
    my $pid_tid = $$;
    $pid_tid .= "_" . threads->tid if $INC{'threads.pm'};

    # see if we have a matching handle
    my $handle = $self->{'_handles'}->{$pid_tid} || undef;

    if ($handle->{'dbh'}) {
        if ($handle->{'dbh'}{'Active'} && $self->{'_check_threshold'} &&
            (time - $handle->{'last_connection_check'} < $self->{'_check_threshold'})) {

            # the handle has been checked recently so just return it
            return $handle->{'dbh'};
        } else {
            if ($self->_check_connection($handle->{'dbh'})) {
                $handle->{'last_connection_check'} = time;
                return $handle->{'dbh'};
            } else {
                # er need to reconnect
                carp "database connection to '${\$self->{'_connection'}}' went away -- reconnecting";

                # try to disconnect but don't care if it fails
                if ($handle->{'dbh'}) {
                    try { $handle->{'dbh'}->disconnect(); } catch {};
                }

                # try to connect again and save the new handle
                $handle->{'dbh'} = $self->_get_connection();
                return $handle->{'dbh'};
            }
        }
    } else {
        $handle->{'dbh'} = $self->_get_connection();
        if ($handle->{'dbh'}) {
            $handle->{'last_connection_check'} = time;
            $self->{'_handles'}->{$pid_tid} = $handle;
            return $handle->{'dbh'};
        }
    }

    return;
}

sub _get_connection {
    my $self = shift;

    my $dbh = undef;
    try {
        $dbh = DBI->connect(@{$self->{'_dsn'}}) || croak "${\$DBI::errstr}\n";

        # run any on_connect sql
        $dbh->do($_) for (@{$self->{'_on_connect'}});
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "could not initialize database connection '${\$self->{'_connection'}}': ${error}";
    };

    return $dbh;
}

# Check the connection is alive
sub _check_connection {
    my $self = shift;
    my $dbh = shift;
    return 0 unless $dbh;

    if ($dbh->{Active} && (my $result = $dbh->ping())) {
        if (int($result)) {
            # DB driver itself claims all is OK, trust it:
            return 1;
        } else {
            # it was "0 but true" meaning the DBD doesn't implement ping and
            # instead we got the default DBI ping implementation. implement
            # our own basic check by performing a real simple query.
            return try {
                return $dbh->do("SELECT 1");
            } catch {
                return 0;
            };
        }
    }

    return 0;
}

# stolen from Hash::Merge::Simple
## no critic (ProhibitUnusedPrivateSubroutines)
sub _merge {
    my ($self, $left, @right) = @_;

    return $left unless @right;
    return $self->_merge($left, $self->_merge(@right)) if @right > 1;

    my ($right) = @right;
    my %merged = %{$left};

    for my $key (keys %{$right}) {
        my ($hr, $hl) = map { ref($_->{$key}) eq "HASH" } $right, $left;

        if ($hr and $hl) {
            $merged{$key} = $self->_merge($left->{$key}, $right->{$key});
        } else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;
}

1;
