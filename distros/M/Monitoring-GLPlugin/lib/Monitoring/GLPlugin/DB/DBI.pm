package Monitoring::GLPlugin::DB::DBI;
our @ISA = qw(Monitoring::GLPlugin::DB);
use strict;

sub fetchrow_array {
  my ($self, $sql, @arguments) = @_;
  my $sth = undef;
  my @row = ();
  my $stderrvar = "";
  $self->set_variable("verbosity", 2);
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "SQL:\n%s\nARGS:\n%s\n",
        $sql, Data::Dumper::Dumper(\@arguments));
    $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    if (scalar(@arguments)) {
      $sth->execute(@arguments) || die DBI::errstr();
    } else {
      $sth->execute() || die DBI::errstr();
    }
    @row = $sth->fetchrow_array();
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper(\@row));
    my $rest = $sth->fetchall_arrayref();
    $sth->finish();
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
  } elsif ($stderrvar) {
    $self->debug(sprintf "stderr %s", $stderrvar) ;
    $self->add_warning($stderrvar);
  }
  return $row[0] unless wantarray;
  return @row;
}

sub fetchall_array {
  my ($self, $sql, @arguments) = @_;
  my $sth = undef;
  my $rows = undef;
  my $stderrvar = "";
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "SQL:\n%s\nARGS:\n%s\n",
        $sql, Data::Dumper::Dumper(\@arguments));
    $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    if (scalar(@arguments)) {
      $sth->execute(@arguments);
    } else {
      $sth->execute();
    }
    $rows = $sth->fetchall_arrayref();
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper($rows));
    $sth->finish();
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
    $rows = [];
  } elsif ($stderrvar) {
    $self->debug(sprintf "stderr %s", $stderrvar) ;
    $self->add_warning($stderrvar);
  }
  return @{$rows};
}

sub execute {
  my ($self, $sql) = @_;
  my $errvar = "";
  my $stderrvar = "";
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "EXEC:\n%s\n", $sql);
    my $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    $sth->execute();
    $sth->finish();
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
  } elsif ($stderrvar || $errvar) {
    $errvar = join("\n", (split(/\n/, $errvar), $stderrvar));
    $self->debug(sprintf "stderr %s", $errvar) ;
    $self->add_warning($errvar);
  }
}

sub DESTROY {
  my ($self) = @_;
  $self->debug(sprintf "disconnecting DBD %s",
      $Monitoring::GLPlugin::DB::session ? "with handle" : "without handle");
  $Monitoring::GLPlugin::DB::session->disconnect() if $Monitoring::GLPlugin::DB::session;
}

sub add_dbi_funcs {
  my ($self) = @_;
  $self->SUPER::add_dbi_funcs();
  {
    no strict 'refs';
    *{'Monitoring::GLPlugin::DB::fetchall_array'} = \&{"Monitoring::GLPlugin::DB::DBI::fetchall_array"};
    *{'Monitoring::GLPlugin::DB::fetchrow_array'} = \&{"Monitoring::GLPlugin::DB::DBI::fetchrow_array"};
    *{'Monitoring::GLPlugin::DB::execute'} = \&{"Monitoring::GLPlugin::DB::DBI::execute"};
  }
}

