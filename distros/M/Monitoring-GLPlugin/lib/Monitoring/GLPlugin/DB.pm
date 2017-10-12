package Monitoring::GLPlugin::DB;
our @ISA = qw(Monitoring::GLPlugin);
use strict;
use File::Basename qw(basename dirname);
use File::Temp qw(tempfile);

{
  our $session = undef;
  our $fetchall_array_cache = {};
}

sub new {
  my ($class, %params) = @_;
  require Monitoring::GLPlugin
      if ! grep /BEGIN/, keys %Monitoring::GLPlugin::;
  require Monitoring::GLPlugin::DB::CSF
      if ! grep /BEGIN/, keys %Monitoring::GLPlugin::DB::CSF::;
  require Monitoring::GLPlugin::DB::DBI
      if ! grep /BEGIN/, keys %Monitoring::GLPlugin::DB::DBI::;
  require Monitoring::GLPlugin::DB::Item
      if ! grep /BEGIN/, keys %Monitoring::GLPlugin::DB::Item::;
  require Monitoring::GLPlugin::DB::TableItem
      if ! grep /BEGIN/, keys %Monitoring::GLPlugin::DB::TableItem::;
  my $self = Monitoring::GLPlugin->new(%params);
  bless $self, $class;
  return $self;
}

sub add_db_modes {
  my ($self) = @_;
  $self->add_mode(
      internal => 'server::connectiontime',
      spec => 'connection-time',
      alias => undef,
      help => 'Time to connect to the server',
  );
  $self->add_mode(
      internal => 'server::sql',
      spec => 'sql',
      alias => undef,
      help => 'any sql command returning a single number',
  );
  $self->add_mode(
      internal => 'server::sqlruntime',
      spec => 'sql-runtime',
      alias => undef,
      help => 'the time an sql command needs to run',
  );
  $self->add_mode(
      internal => 'internal::encode',
      spec => 'encode',
      alias => undef,
      help => 'url-encodes stdin',
  );
}

sub add_db_args {
  my ($self) = @_;
  $self->add_arg(
      spec => 'dbthresholds:s',
      help => '--dbthresholds
   Read thresholds from a database table',
      required => 0,
      env => 'DBTHRESHOLDS',
  );
  $self->add_arg(
      spec => 'notemp',
      help => '--notemp
   Ignore temporary databases/tablespaces',
      required => 0,
  );
  $self->add_arg(
      spec => 'commit',
      help => '--commit
   turns on autocommit for the dbd::* module',
      default => 0,
      required => 0,
  );
  $self->add_arg(
      spec => 'method:s',
      help => '--method
   how to connect to the database, perl-dbi or calling a command line client.
   Default is "dbi", which requires the installation of a suitable perl-module.',
      default => 'dbi',
      required => 0,
  );
}

sub get_db_tables {
#  $self->get_db_tables([
#    ['databases', 'select * from', 'Classes::POSTGRES::Component::DatabaseSubsystem::Database']
#  ]);
  my ($self, $infos) = @_;
  foreach my $info (@{$infos}) {
    my $arrayname = $info->[0];
    my $sql = $info->[1];
    my $class = $info->[2];
    my $filter = $info->[3];
    my $mapping = $info->[4];
    my $args = $info->[5];
    $self->{$arrayname} = [] if ! exists $self->{$arrayname};
    my $max_idx = scalar(@{$mapping});;
    foreach my $row ($self->fetchall_array($sql, @{$args})) {
      my $col_idx = -1;
      my $params = {};
      while ($col_idx < $max_idx) {
        $params->{$mapping->[$col_idx]} = $row->[$col_idx];
        $col_idx++;
      }
      my $new_object = $class->new(%{$params});
      next if (defined $filter && ! &$filter($new_object));
      push(@{$self->{$arrayname}}, $new_object);
    }
  }
}

sub validate_args {
  my ($self) = @_;
  $self->SUPER::validate_args();
  if ($self->opts->name && $self->opts->name =~ /(select|exec)%20/i) {
    my $name = $self->opts->name;
    $name =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $self->override_opt('name', $name);
  }
}

sub no_such_mode {
  my ($self) = @_;
  if (ref($self) eq "Classes::Device") {
    $self->add_unknown('the device is no known type of database server');
  } else {
    bless $self, "Monitoring::GLPlugin::DB";
    $self->init();
  }
  if (ref($self) eq "Monitoring::GLPlugin") {
    printf "Mode %s is not implemented for this type of device\n",
        $self->opts->mode;
    exit 3;
  }
}

sub init {
  my ($self) = @_;
  if ($self->mode =~ /^server::connectiontime/) {
    my $connection_time = $self->{tac} - $self->{tic};
    $self->set_thresholds(warning => 1, critical => 5);
    $self->add_message($self->check_thresholds($connection_time),
         sprintf "%.2f seconds to connect as %s",
              $connection_time, $self->opts->username,);
    $self->add_perfdata(
        label => 'connection_time',
        value => $connection_time,
    );
  } elsif ($self->mode =~ /^server::sqlruntime/) {
    my $tic = Time::HiRes::time();
    my @genericsql = $self->fetchrow_array($self->opts->name);
    my $runtime = Time::HiRes::time() - $tic;
    # normally, sql errors and stderr result in CRITICAL or WARNING
    # we can clear these errors if we are only interested in the runtime
    $self->clear_all() if $self->check_messages() &&
        defined $self->opts->mitigation && $self->opts->mitigation == 0;
    $self->set_thresholds(warning => 1, critical => 5);
    $self->add_message($self->check_thresholds($runtime),
        sprintf "%.2f seconds to execute %s",
            $runtime,
            $self->opts->name2 ? $self->opts->name2 : $self->opts->name);
    $self->add_perfdata(
        label => "sql_runtime",
        value => $runtime,
        uom => "s",
    );
  } elsif ($self->mode =~ /^server::sql/) {
    if ($self->opts->regexp) {
      # sql output is treated as text
      my $pattern = $self->opts->name2;
      #if ($self->opts->name2 eq $self->opts->name) {
      my $genericsql = $self->fetchrow_array($self->opts->name);
      if (! defined $genericsql) {
        $self->add_unknown(sprintf "got no valid response for %s",
            $self->opts->name);
      } else {
        if (substr($pattern, 0, 1) eq '!') {
          $pattern =~ s/^!//;
          if ($genericsql !~ /$pattern/) {
            $self->add_ok(
                sprintf "output %s does not match pattern %s",
                    $genericsql, $pattern);
          } else {
            $self->add_critical(
                sprintf "output %s matches pattern %s",
                    $genericsql, $pattern);
          }
        } else {
          if ($genericsql =~ /$pattern/) {
            $self->add_ok(
                sprintf "output %s matches pattern %s",
                    $genericsql, $pattern);
          } else {
            $self->add_critical(
                sprintf "output %s does not match pattern %s",
                    $genericsql, $pattern);
          }
        }
      }
    } else {
      # sql output must be a number (or array of numbers)
      my @genericsql = $self->fetchrow_array($self->opts->name);
      #$self->create_opt("name2") if ! $self->opts->name2
      $self->override_opt("name2", $self->opts->name) if ! $self->opts->name2;
      if (! @genericsql) {
          #(scalar(grep { /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/ } @{$self->{genericsql}})) ==
          #scalar(@{$self->{genericsql}}))) {
        $self->add_unknown(sprintf "got no valid response for %s",
            $self->opts->name);
      } else {
        # name2 in array
        # units in array

        $self->set_thresholds(warning => 1, critical => 5);
        $self->add_message(
          # the first item in the list will trigger the threshold values
            $self->check_thresholds($genericsql[0]),
                sprintf "%s: %s%s",
                $self->opts->name2 ? lc $self->opts->name2 : lc $self->opts->name,
              # float as float, integers as integers
                join(" ", map {
                    (sprintf("%d", $_) eq $_) ? $_ : sprintf("%f", $_)
                } @genericsql),
                $self->opts->units ? $self->opts->units : "");
        my $i = 0;
        # workaround... getting the column names from the database would be nicer
        my @names2_arr = split(/\s+/, $self->opts->name2);
        foreach my $t (@genericsql) {
          $self->add_perfdata(
              label => $names2_arr[$i] ? lc $names2_arr[$i] : lc $self->opts->name,
              value => (sprintf("%d", $t) eq $t) ? $t : sprintf("%f", $t),
              uom => $self->opts->units ? $self->opts->units : "",
          );
          $i++;
        }
      }
    }
  } else {
    bless $self, "Monitoring::GLPlugin"; # see above: no_such_mode
  }
}

sub compatibility_methods {
  my ($self) = @_;
  $self->{handle} = $self;
  $self->SUPER::compatibility_methods() if $self->SUPER::can('compatibility_methods');
}

sub has_threshold_table {
  my ($self) = @_;
  # has to be implemented in each database driver class
  return 0;
}

sub set_thresholds {
  my ($self, %params) = @_;
  $self->SUPER::set_thresholds(%params);
  if (defined $self->opts->dbthresholds && $self->has_threshold_table()) {
    #
    my @dbthresholds = $self->fetchall_array(
        sprintf "SELECT * FROM %s WHERE mode = '%s'",
            $self->{has_threshold_table}, $self->opts->mode
    );
    if (@dbthresholds) {
      # | mode | =metric | warning | critical |
      # | mode | =dbthresholds | warning | critical |
      # | mode | =name2 | warning | critical |
      # | mode | =name | warning | critical |
      # | mode | NULL | warning | critical |
      my %newparams = ();
      my @metricmatches = grep { $params{metric} eq $_->[1] }
          grep { defined $_->[1] }
          grep { exists $params{metric} } @dbthresholds;
      my @dbtmatches = grep { $self->opts->dbthresholds eq $_->[1] }
          grep { defined $_->[1] }
          grep { $self->opts->dbthresholds ne '1' } @dbthresholds;
      my @name2matches = grep { $self->opts->name2 eq $_->[1] }
          grep { defined $_->[1] }
          grep { $self->opts->name2 } @dbthresholds;
      my @namematches = grep { $self->opts->name eq $_->[1] }
          grep { defined $_->[1] }
          grep { $self->opts->name } @dbthresholds;
      my @modematches = grep { ! defined $_->[1] } @dbthresholds;
      if (@metricmatches) {
        $newparams{warning} = $metricmatches[0]->[2];
        $newparams{critical} = $metricmatches[0]->[3];
      } elsif (@dbtmatches) {
        $newparams{warning} = $dbtmatches[0]->[2];
        $newparams{critical} = $dbtmatches[0]->[3];
      } elsif (@name2matches) {
        $newparams{warning} = $name2matches[0]->[2];
        $newparams{critical} = $name2matches[0]->[3];
      } elsif (@namematches) {
        $newparams{warning} = $namematches[0]->[2];
        $newparams{critical} = $namematches[0]->[3];
      } elsif (@modematches) {
        $newparams{warning} = $modematches[0]->[2];
        $newparams{critical} = $modematches[0]->[3];
      }
      delete $newparams{warning} if
          (! defined $newparams{warning} ||
              $newparams{warning} !~ /^[-+]?[0-9]*\.?[0-9]+$/);
      delete $newparams{critical} if
          (! defined $newparams{critical} ||
              $newparams{critical} !~ /^[-+]?[0-9]*\.?[0-9]+$/);
      $newparams{metric} = $params{metric} if exists $params{metric};
      $self->debug("overwrite thresholds with db-values: %s", Data::Dumper::Dumper(\%newparams)) if scalar(%newparams);
      $self->SUPER::set_thresholds(%newparams) if scalar(%newparams);
    }
  }
}

sub find_extcmd {
  my ($self, $cmd, @envpaths) = @_;
  my @paths = $^O =~ /MSWin/ ?
      split(';', $ENV{PATH}) : split(':', $ENV{PATH});
  return $self->{extcmd} if $self->{extcmd};
  foreach my $path (@envpaths) {
    if ($ENV{$path}) {
      if (! -d $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd) &&
          -x $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd)) {
        $self->{extcmd} = $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd);
        last;
      } elsif (! -d $path.'/bin/'.$cmd && -x $path.'/bin/'.$cmd) {
        $self->{extcmd} = $path.'/bin/'.$cmd;
        last;
      }
    }
  }
  return $self->{extcmd} if $self->{extcmd};
  foreach my $path (@paths) {
    if (! -d $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd) &&
        -x $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd)) {
      $self->{extcmd} = $path.'/'.($^O =~ /MSWin/ ? $cmd.'.exe' : $cmd);
      if ($^O =~ /MSWin/) {
        map { $ENV{$_} = $path } @envpaths;
      } else {
        if (basename(dirname($path)) eq "bin") {
          $path = dirname(dirname($path));
        }
        map { $ENV{$_} = $path } @envpaths;
      }
      last;
    }
  }
  return $self->{extcmd};
}

sub write_extcmd_file {
  my ($self, $sql) = @_;
}

sub create_extcmd_files {
  my ($self) = @_;
  my $template = $self->opts->mode.'XXXXX';
  if ($^O =~ /MSWin/) {
    $template =~ s/::/_/g;
  }
  ($self->{sql_commandfile_handle}, $self->{sql_commandfile}) =
      tempfile($template, SUFFIX => ".sql",
      DIR => $self->system_tmpdir() );
  close $self->{sql_commandfile_handle};
  ($self->{sql_resultfile_handle}, $self->{sql_resultfile}) =
      tempfile($template, SUFFIX => ".out",
      DIR => $self->system_tmpdir() );
  close $self->{sql_resultfile_handle};
  ($self->{sql_outfile_handle}, $self->{sql_outfile}) =
      tempfile($template, SUFFIX => ".out",
      DIR => $self->system_tmpdir() );
  close $self->{sql_outfile_handle};
  $Monitoring::GLPlugin::DB::sql_commandfile = $self->{sql_commandfile};
  $Monitoring::GLPlugin::DB::sql_resultfile = $self->{sql_resultfile};
  $Monitoring::GLPlugin::DB::sql_outfile = $self->{sql_outfile};
}

sub delete_extcmd_files {
  my ($self) = @_;
  unlink $Monitoring::GLPlugin::DB::sql_commandfile
      if $Monitoring::GLPlugin::DB::sql_commandfile &&
      -f $Monitoring::GLPlugin::DB::sql_commandfile;
  unlink $Monitoring::GLPlugin::DB::sql_resultfile
      if $Monitoring::GLPlugin::DB::sql_resultfile &&
      -f $Monitoring::GLPlugin::DB::sql_resultfile;
  unlink $Monitoring::GLPlugin::DB::sql_outfile
      if $Monitoring::GLPlugin::DB::sql_outfile &&
      -f $Monitoring::GLPlugin::DB::sql_outfile;
}

sub fetchall_array_cached {
  my $self = shift;
  my $sql = shift;
  my @arguments = @_;
  my @rows = ();
  my $key = Digest::MD5::md5_hex($sql.Data::Dumper::Dumper(\@arguments));
  if (! exists $Monitoring::GLPlugin::DB->{fetchall_array_cache}->{$key}) {
    @rows = $self->fetchall_array($sql, @arguments);
    $Monitoring::GLPlugin::DB->{fetchall_array_cache}->{$key} = \@rows;
  } else {
    $self->debug(sprintf "cached SQL:\n%s\n", $sql);
    @rows = @{$Monitoring::GLPlugin::DB->{fetchall_array_cache}->{$key}};
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper(\@rows));
  }
  return @rows;
}


sub DESTROY {
  my ($self) = @_;
  $self->delete_extcmd_files();
}

1;

__END__
