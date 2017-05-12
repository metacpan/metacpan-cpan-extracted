package Mojolicious::Command::jobcontrol;
$Mojolicious::Command::jobcontrol::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Command';

use Data::Dumper;
use Digest::Bcrypt;
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use File::Path;
use File::Basename;

has description => 'JobControl Commands';
has usage => sub { shift->extract_usage };

sub run {
  my ( $self, $command, @args ) = @_;

  if ( !$command || $command eq "help" ) {
    print "Usage:\n";
    print "$0 jobcontrol <command> [<options>]\n";
    print "\n";
    print "Commands:\n";
    print "\n";
    print "version       print the version.\n";
    print "\n";
    print "setup         create all required folders\n";
    print
      "systemd -c    create systemd unit files for JobControl and Minion.\n";
    print "upstart -c    create upstart files for JobControl and Minion.\n";
    print "\n";
    print "User Management:\n";
    print "\n";
    print "adduser -u username -p password        will add a new user\n";
    print "deluser -u username                    will delete a user\n";
    print "listuser                               list all users\n";
    exit 0;
  }

  if ( $command eq "version" ) {
    print "This is Rex::JobControl (" . $Rex::JobControl::VERSION . ")\n";
    exit 0;
  }

  if ( $command eq "systemd" ) {
    my ( $create_unit, $start, $stop, $restart ) = @_;

    GetOptionsFromArray \@args,
      'c|create-unit' => sub { $create_unit = 1 },
      's|start'       => sub { $start       = 1 },
      'r|restart'     => sub { $restart     = 1 },
      'k|stop'        => sub { $stop        = 1 };

    if ($create_unit) {
      $self->create_systemd_unit();
    }
  }

  if ( $command eq "upstart" ) {
    my ( $create_unit, $start, $stop, $restart ) = @_;

    GetOptionsFromArray \@args,
      'c|create-unit' => sub { $create_unit = 1 },
      's|start'       => sub { $start       = 1 },
      'r|restart'     => sub { $restart     = 1 },
      'k|stop'        => sub { $stop        = 1 };

    if ($create_unit) {
      $self->create_upstart_unit();
    }
  }

  if ( $command eq "setup" ) {
    my $changed = 0;

    if ( !-d $self->app->config->{project_path} ) {
      $self->app->log->info(
        "Creating project path: " . $self->app->config->{project_path} );
      File::Path::make_path( $self->app->config->{project_path} );
      $changed = 1;
    }

    if ( !-d dirname( $self->app->config->{minion_db_file} ) ) {
      $self->app->log->info( "Creating minion db path: "
          . dirname( $self->app->config->{minion_db_file} ) );
      File::Path::make_path( dirname( $self->app->config->{minion_db_file} ) );
      $changed = 1;
    }

    if ( !-d $self->app->config->{upload_tmp_path} ) {
      $self->app->log->info(
        "Creating upload_tmp_path: " . $self->app->config->{upload_tmp_path} );
      File::Path::make_path( $self->app->config->{upload_tmp_path} );
      $changed = 1;
    }

    if ( !-d dirname( $self->app->config->{auth}->{passwd} ) ) {
      $self->app->log->info( "Creating passwd path: "
          . dirname( $self->app->config->{auth}->{passwd} ) );
      File::Path::make_path( dirname( $self->app->config->{auth}->{passwd} ) );
      $changed = 1;
    }

    if ( exists $self->app->config->{log}->{audit_log}
      && !-d dirname( $self->app->config->{log}->{audit_log} ) )
    {
      $self->app->log->info( "Creating audit.log path: "
          . dirname( $self->app->config->{log}->{audit_log} ) );
      File::Path::make_path(
        dirname( $self->app->config->{log}->{audit_log} ) );
      $changed = 1;
    }

    if ( exists $self->app->config->{log}->{access_log}
      && !-d dirname( $self->app->config->{log}->{access_log} ) )
    {
      $self->app->log->info( "Creating access.log path: "
          . dirname( $self->app->config->{log}->{access_log} ) );
      File::Path::make_path(
        dirname( $self->app->config->{log}->{access_log} ) );
      $changed = 1;
    }

    if ( !-f $self->app->config->{auth}->{passwd} ) {
      $self->app->log->info(
        "No passwd file found. Creating one with user 'admin' and password 'admin'."
      );
      $self->add_user( "admin", "admin" );
      $changed = 1;
    }

    if ( $changed == 0 ) {
      $self->app->log->info("Everything seems ok.");
    }

  }

  if ( $command eq "adduser" ) {
    my ( $user, $password );

    GetOptionsFromArray \@args,
      'u|user=s'     => sub { $user     = $_[1] },
      'p|password=s' => sub { $password = $_[1] };

    $self->add_user( $user, $password );
  }

  if ( $command eq "deluser" ) {

    my $user;

    GetOptionsFromArray \@args, 'u|user=s' => sub { $user = $_[1] };

    my @lines =
      grep { !m/^$user:/ }
      eval { local (@ARGV) = ( $self->app->config->{auth}->{passwd} ); <>; };

    open( my $fh, ">", $self->app->config->{auth}->{passwd} ) or die($!);
    print $fh join( "\n", @lines );
    close($fh);
  }

  if ( $command eq "listuser" ) {
    my @lines =
      eval { local (@ARGV) = ( $self->app->config->{auth}->{passwd} ); <>; };
    chomp @lines;

    for my $l (@lines) {
      my ( $user, $pass ) = split( /:/, $l );
      print "> $user\n";
    }
  }

}

sub add_user {
  my ( $self, $user, $password ) = @_;

  $self->app->log->debug("Creating new user $user with password $password");

  my $salt = $self->app->config->{auth}->{salt};
  my $cost = $self->app->config->{auth}->{cost};

  my $bcrypt = Digest::Bcrypt->new;
  $bcrypt->salt($salt);
  $bcrypt->cost($cost);
  $bcrypt->add($password);

  my $pw = $bcrypt->hexdigest;

  open( my $fh, ">>", $self->app->config->{auth}->{passwd} ) or die($!);
  print $fh "$user:$pw\n";
  close($fh);

}

sub create_upstart_unit {
  my ($self) = @_;

  my $pid_file = $self->app->config->{hypnotoad}->{pid_file};

  my $whereis_hypnotoad = qx{which hypnotoad};
  chomp $whereis_hypnotoad;

  open( my $fh, ">", "/etc/init/rex-jobcontrol.conf" ) or die($!);
  print $fh qq~# Rex::JobControl

description     "Rex::JobControl upstart job"

start on runlevel [2345]
stop on runlevel [!2345]

pre-start exec $whereis_hypnotoad $0
post-stop exec $whereis_hypnotoad $0 -s
~;
  close($fh);

  open( $fh, ">", "/etc/init/rex-jobcontrol-minion.conf" ) or die($!);
  print $fh qq~# Rex::JobControl Minion

description     "Rex::JobControl Minion upstart job"

start on runlevel [2345]
stop on runlevel [!2345]

exec $0 minion worker
~;
  close($fh);

}

sub create_systemd_unit {
  my ($self) = @_;

  my $pid_file = $self->app->config->{hypnotoad}->{pid_file};

  my $whereis_hypnotoad = qx{which hypnotoad};
  chomp $whereis_hypnotoad;

  open( my $fh, ">", "/lib/systemd/system/rex-jobcontrol.service" ) or die($!);
  print $fh qq~[Unit]
Description=Rex JobControl Server
After=network.target

[Service]
Type=simple
SyslogIdentifier=rex-jobcontrol
PIDFile=$pid_file
ExecStart=$whereis_hypnotoad -f $0
ExecStop=$whereis_hypnotoad -s $0
ExecReload=$whereis_hypnotoad $0
~;
  close($fh);

  open( my $fh_m, ">", "/lib/systemd/system/rex-jobcontrol-minion.service" )
    or die($!);
  print $fh_m qq~[Unit]
Description=Rex JobControl Minion
After=network.target

[Service]
Type=simple
SyslogIdentifier=rex-jobcontrol-minion
ExecStart=$0 minion worker
~;
  close($fh_m);

}

1;
