package Mojar::Mysql::Replication;
use Mojo::Base -base;

our $VERSION = 0.034;

use Carp 'croak';
use Mojar::Util qw(as_bool dumper lc_keys);
use Mojar::Log;

# Attributes

# Time
has stop_io_run_time => 2;
has stop_sql_max_wait => 55;

# Behaviour
has safety => 'medium_safety';

# Accessors
has 'connector';
has log => sub { Mojar::Log->new(pattern => '%y%m%d %H%M%S') };

# Public methods

sub stop_io {
  my $self = shift;
  eval {
    $self->connector->connection->do(q{STOP SLAVE IO_THREAD});
    1;
  }
  or do {
    my $e = $@ // 'unknown failure';
    if ($e =~ / failed: This operation requires a running slave/) {
      $self->log->warn('stop_io: Was not a running slave') if $self->log;
      return undef;
    }
    else {
      $self->log->error("stop_io: $e") if $self->log;
      croak "Failed to stop io_thread: $e";
    }
  };
  return $self;
}

sub start_io {
  my $self = shift;
  eval {
    $self->connector->connection->do(q{START SLAVE IO_THREAD});
    1;
  }
  or do {
    my $e = $@ // 'unknown failure';
    if ($e =~
        / failed: This operation cannot be performed with a running slave/) {
      $self->log->warn('start_io: Was already a running slave') if $self->log;
      return undef;
    }
    else {
      $self->log->error("start_io: $e") if $self->log;
      croak "Failed to start io_thread: $e";
    }
  };
  return $self;
}

sub stop_sql {
  my $self = shift;
  eval {
    $self->connector->connection->do(q{STOP SLAVE SQL_THREAD});
    1;
  }
  or do {
    my $e = $@ // '';
    if ($e =~ / failed: This operation requires a running slave/) {
      $self->log->warn(q{stop_sql: Was not a running slave}) if $self->log;
      return undef;
    }
    else {
      $self->log->error("stop_sql: $e") if $self->log;
      croak "Failed to stop sql_thread: $e";
    }
  };
  return $self;
}

sub start_sql {
  my $self = shift;
  eval {
    $self->connector->connection->do(q{START SLAVE SQL_THREAD});
    1;
  }
  or do {
    my $e = $@ // '';
    if ($e =~
        / failed: This operation cannot be performed with a running slave/) {
      $self->log->warn(q{start_sql: Was already a running slave}) if $self->log;
      return undef;
    }
    else {
      $self->log->error("start_sql: $e") if $self->log;
      croak "Failed to start sql_thread: $e";
    }
  };
  return $self;
}

sub sql_thread_waiting {
  my $self = shift;
  my ($is_waiting, $repl_found, $threads);
  eval {
    $threads = $self->connector->connection->threads;
  }
  or do {
    my $e = $@ // 'unknown failure';
    $self->log->error("sql_thread_waiting: $e") if $self->log;
    croak "Problem found trying to check sql_thread\n$e";
  };
  for my $t (grep {$_->{user} eq 'system user'} @$threads) {
    ++$repl_found;
    $is_waiting = 1 if $t->{state}
        and $t->{state} =~ /^(?:Slave has|Has) read all relay log/;
  }
  croak 'Replication does not appear to be running' unless $repl_found;
  return $is_waiting;
}

sub sql_thread_aligned {
  my $self = shift;

  my $status = $self->status;
  croak q{Not configured as a slave} unless $status->{master_host};

  return ($status->{master_log_file} eq $status->{relay_master_log_file}
      and $status->{read_master_log_pos} == $status->{exec_master_log_pos});
}

sub status {
  my $self = shift;
  my $status;
  eval {
    $status = lc_keys($self->connector->connection->selectrow_hashref(
        q{SHOW SLAVE STATUS}) || {});
  }
  or do {
    my $e = $@ // 'unknown failure';
    $self->log->error("status: $e") if $self->log;
    croak 'Failed to get replication status';
  };
  return $status;
}

sub stop {
  my ($self, $safety) = @_;
  $safety //= $self->safety;
#TODO: Check whether has privs to see system_user threads

  # max_safety == outside_transaction
  # medium_safety == trust_transaction
  # low_safety == time_limited
  # no_safety == emergency
  if ($safety eq 'no_safety' or $safety eq 'emergency') {
    $self->stop_io;
    $self->stop_sql;
  }
  elsif ($safety eq 'max_safety' or $safety eq 'outside_transaction') {
    $self->stop_io;
    if ($self->status->{slave_sql_running} =~ /^No/i) {
      $self->start_sql;
      sleep 1;
    }
    sleep 1 while not $self->sql_thread_waiting;

    while (not $self->sql_thread_aligned) {
      $self->start_io;
      sleep $self->stop_io_run_time;
      $self->stop_io;
      sleep 1 while not $self->sql_thread_waiting;
    }
    $self->stop_sql;
  }
  elsif ($safety eq 'medium_safety' or $safety eq 'trust_transaction') {
    $self->stop_io;
    return $self unless $self->status->{slave_sql_running} =~ /^Yes/i;
    sleep 1 while not $self->sql_thread_waiting;
    $self->stop_sql;
  }
  elsif ($safety eq 'low_safety' or $safety eq 'time_limited') {
    $self->stop_io;
    return $self unless $self->status->{slave_sql_running} =~ /^Yes/i;
    my $waited = 0;
    sleep 1 while not $self->sql_thread_waiting
        and $waited++ < $self->stop_sql_max_wait;
    $self->stop_sql;
  }
  else {
    croak "Unrecognised safety level ($safety)";
  }
  return $self;
}

sub io_run_time {
  my $self = shift;
  my ($thread, undef) = $self->system_threads;
  unless (defined $thread) {
    sleep 5;
    ($thread, undef) = $self->system_threads;
  }
  return undef unless defined $thread;
  return $thread->{time} < 4_000_000_000 ? $thread->{time} : 0;
}

sub sql_lag {
  my $self = shift;
  my (undef, $thread) = $self->system_threads;
  unless (defined $thread) {
    sleep 5;
    (undef, $thread) = $self->system_threads;
  }
  return undef unless defined $thread;
  return $thread->{time} < 4_000_000_000 ? $thread->{time} : 0;
}

sub system_threads {
  my ($self, $threads) = @_;
  my ($io_thread, $sql_thread, @candidates);
  $_->{user} eq 'system user' and push @candidates, $_
    for @{$threads // $self->connector->connection->threads};
  return (undef, undef) unless @candidates;

  # The following assumes there are at most two system threads
  # Examine first candidate
  my $hint = $self->_system_thread_spotter($candidates[0]);
  if ($hint == 1) {
    $io_thread = $candidates[0];
    $sql_thread = $candidates[1] if @candidates > 1;
    return ($io_thread, $sql_thread);
  }
  elsif ($hint == 2) {
    $sql_thread = $candidates[0];
    $io_thread = $candidates[1] if @candidates > 1;
    return ($io_thread, $sql_thread);
  }
  elsif (@candidates == 1) {
    $self->log->error("Failed to identify thread\n". dumper $candidates[0])
      if $self->log;
    return undef;
  }

  # Examine second candidate
  $hint = $self->_system_thread_spotter($candidates[1]);
  if ($hint == 1) {
    return ($io_thread, $sql_thread) = ($candidates[1], $candidates[0]);
  }
  elsif ($hint == 2) {
    return ($io_thread, $sql_thread) = @candidates;
  }
  $self->log->error("Failed to identify thread\n". dumper $candidates[1])
    if $self->log;
  return undef;
}

sub active_threads {
  my ($self, $threads) = @_;
  $threads //= $self->connector->connection->threads;
  my @candidates;
  $_->{user} and $_->{user} ne 'system user'
      and $_->{state} and $_->{state} ne 'Sleep'
      and push @candidates, $_ for @$threads;
  return \@candidates;
}

sub purge_binary_logs {
  my ($self, $master, $slaves, $keep) = @_;
  for my $c ($master, @$slaves) {
    croak 'Requires database connectors'
      unless defined $c and ref $c and $c->can('connection');
  }

  # Check the master
  my $master_dbh = $master->connection;
  my $logs = $master_dbh->selectall_arrayref_hashrefs(
q{SHOW MASTER LOGS}
  );
  return 0 unless @$logs;

  # Check each of the slaves
  my $required = $logs->[-1]{log_name};
  for my $s (@$slaves) {
    my $r = $self->new(connector => $s);
    my $referenced = $r->status->{master_log_file}
      or croak 'Failed to interpret slave status';
    $required = $referenced if $referenced lt $required;
  }
  # $required is the oldest bin log required

  # Check it is still available
  my $required_index = -1;
  for (my $i = 0; $i < @$logs; ++$i) {
    $required_index = $i and last if $logs->[$i]{log_name} eq $required;
  }
  die "Required binary log not available ($required)"
    unless $required_index >= 0;

  $required_index = $#{$logs} - $keep
    if $keep and $#{$logs} - $keep < $required_index;

  die sprintf 'Purging to %s', $logs->[$required_index]{log_name};
}

sub incr_skip_counter {
  my ($self, $count) = @_;
  $count //= 1;
  return $self->connector->connection->global_var(
      sql_slave_skip_counter => $count);
}

sub incr_heartbeat {
  my ($self, $schema, $table, $column, $where) = @_; $where //= '1';
  $self->connector->connection->do(sprintf
q{UPDATE `%s`.`%s`
SET `%s` = `%s` + 1
WHERE %s},
    $schema, $table,
    $column, $column,
    $where
  );
}

sub repair {
  my ($self, $error, $repair_map) = @_;
  my $dbh = $self->connector->connection;
  # ...
  return !! $self->start_sql;
}

sub errored {
  my ($self, $status) = @_;
  $status //= $self->status;
  return ($status->{last_error} // sprintf 'Error: %u', $status->{last_errno})
    if not as_bool($status->{slave_sql_running}) and $status->{last_errno};
  return undef;
}

sub _system_thread_spotter {
  my ($self, $thread) = @_;
  # 1: $thread is the io_thread
  # 2: $thread is the sql_thread
  # 0: failed to determine
  return 0 unless ref $thread eq 'HASH';
  return 2 if defined $thread->{db};
  return 1 if $thread->{state} =~ /^Waiting for master to send event/;
  return 2 if $thread->{state} =~ m{
      ^Waiting\ for\ the\ next\ event
      | ^Reading\ event\ from\ the\ relay
      | ^Making\ temp\ file
      | ^Has\ read\ all\ relay\ log;\ waiting\ for\ the
      | ^Slave\ has\ read\ all\ relay\ log;\ waiting\ for\ the
      | freeing\ items
      }x;
  return 0;  # Don't know
}

1;
__END__

=head1 NAME

Mojar::Mysql::Replication - Monitor and control the replication threads

=head1 SYNOPSIS

  use Mojar::Mysql::Replication;
  my $repl = Mojar::Mysql::Replication->new(connector => ...);
  say 'Lag: ', $repl->sql_lag;

=head1 DESCRIPTION

A class for monitoring and managing replication threads.

=head1 USAGE

First create a replication object (manager) that knows how to connect to the
replicating database.

  use Mojar::Mysql::Replication;
  use Mojar::Mysql::Connector (
    cnf => '...',
    -connector => 1
  );
  my $repl = Mojar::Mysql::Replication->new(
    connector => $self->connector,
    log => $self->log
  );

Then you can monitor the status of its replication.

  $connection_time = $repl->io_run_time;
  $lag = $repl->sql_lag;
  $required_binlog = $repl->status->{master_log_file};

And you can manage replication.

  $repl->safety('max_safety')->stop;
  $repl->start_io->start_sql;

=head1 RATIONALE

Replication is most often used for scaling out for performance, protection from
potentially interfering readers, and data security.  There are, however, very
few tools to help monitor and manage replication, probably due to the fiddliness
of the details.  At one site this package helps manage 100+ MySQL servers.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006--2014, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<MySQL manual|http://dev.mysql.com/doc/refman/5.6/en/replication.html>,
L<Percona Toolkit|http://www.percona.com/software/percona-toolkit>.
