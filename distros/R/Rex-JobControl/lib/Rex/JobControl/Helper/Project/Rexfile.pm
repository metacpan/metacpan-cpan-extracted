#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::JobControl::Helper::Project::Rexfile;
$Rex::JobControl::Helper::Project::Rexfile::VERSION = '0.18.0';
use strict;
use warnings;
use File::Spec;
use File::Path;
use File::Basename;
use YAML;
use Capture::Tiny qw'capture';

use Rex::JobControl::Helper::Chdir;
use Data::Dumper;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  $self->load;

  return $self;
}

sub load {
  my ($self) = @_;

  if ( -f $self->_config_file() ) {
    $self->{rex_configuration} = YAML::LoadFile( $self->_config_file );
  }
}

sub project     { (shift)->{project} }
sub name        { (shift)->{rex_configuration}->{name} }
sub url         { (shift)->{rex_configuration}->{url} }
sub description { (shift)->{rex_configuration}->{description} }
sub groups      { (shift)->{rex_configuration}->{rex}->{groups} }
sub directory   { (shift)->{directory} }
sub rexfile     { (shift)->{rex_configuration}->{rexfile} }

sub _config_file {
  my ($self) = @_;
  return File::Spec->catfile( $self->project->project_path(),
    "rex", $self->{directory}, "rex.conf.yml" );
}

sub create {
  my ( $self, %data ) = @_;

  my $rex_path = File::Spec->catdir( $self->project->project_path,
    "rex", $self->{directory} );

  $self->project->app->log->debug(
    "Creating new Rexfile $self->{directory} in $rex_path.");

  File::Path::make_path($rex_path);

  my $rexfile = basename( $self->{url} );
  $rexfile =~ s/(\.git|\.tar\.gz)$//;

  my $url = $self->{url};
  chwd "$rex_path", sub {
    my $rexify_cmd = $self->project->app->config->{rexify};
    my @out        = `$rexify_cmd --init=$url 2>&1`;
    chomp @out;

    $self->project->app->log->debug("Output of rexify --init=$url");
    for my $l (@out) {
      $self->project->app->log->debug("rexfile: $l");
    }
  };

  my @tasks;
  my $rex_info;

  chwd "$rex_path/$rexfile", sub {
    my $rex_cmd = $self->project->app->config->{rex};
    my $out     = `$rex_cmd -Ty 2>&1`;
    eval { $rex_info = YAML::Load($out); } or do {
      $self->project->app->log->error("Error reading Rexfile information.");
      $self->project->app->log->error("$out");
      $self->project->app->log->error(
        "Please try to run rex -Ty on the Rexfile to see the error.");
    };
  };

  delete $data{directory};

  my $rex_configuration = {
    %data,
    rexfile => $rexfile,
    rex     => $rex_info,
  };

  YAML::DumpFile( "$rex_path/rex.conf.yml", $rex_configuration );
}

sub tasks {
  my ($self) = @_;
  return ( $self->{rex_configuration}->{rex}->{tasks} || [] );
}

sub environments {
  my ($self) = @_;
  return ( $self->{rex_configuration}->{rex}->{envs} || [] );
}

sub all_server {
  my ($self) = @_;

  my @all_server;

  for my $group ( keys %{ $self->groups } ) {
    push @all_server,
      ( map { $_ = { name => $_->{name}, group => $group, %{$_} } }
        @{ $self->groups->{$group} } );
  }

  return \@all_server;
}

sub reload {
  my ($self) = @_;

  my $rex_path = File::Spec->catdir( $self->project->project_path,
    "rex", $self->{directory} );

  my $rexfile = $self->rexfile;
  my $url     = $self->url;

  chwd "$rex_path", sub {
    my $rexify_cmd = $self->project->app->config->{rexify};
    my @out        = `$rexify_cmd --init=$url 2>&1`;
    chomp @out;

    $self->project->app->log->debug("Output of rexify --init=$url");
    for my $l (@out) {
      $self->project->app->log->debug("rexfile: $l");
    }
  };

  my @tasks;
  my $rex_info;

  chwd "$rex_path/$rexfile", sub {
    my $rex_cmd = $self->project->app->config->{rex};
    my $out     = `$rex_cmd -Ty`;
    $rex_info = YAML::Load($out);
  };

  my $rex_configuration = {
    name    => $self->name,
    url     => $url,
    rexfile => $rexfile,
    rex     => $rex_info,
  };

  YAML::DumpFile( "$rex_path/rex.conf.yml", $rex_configuration );

}

sub remove {
  my ($self) = @_;
  my $rexfile_path = File::Spec->catdir( $self->project->project_path,
    "rex", $self->{directory} );

  File::Path::remove_tree($rexfile_path);
}

sub execute {
  my ( $self, %option ) = @_;

  my $task   = $option{task};
  my $job    = $option{job};
  my @server = @{ $option{server} };
  my $cmdb   = $option{cmdb};

  if ( scalar @server == 0 ) {
    @server = ("<local>");
  }

  my $rex_path = File::Spec->catdir( $self->project->project_path,
    "rex", $self->{directory}, $self->rexfile );

  $self->project->app->log->debug("rex_path: $rex_path");

  my @ret;

  my $all_server = $self->project->all_server;

  for my $srv (@server) {

    my ($srv_object) = grep { $_->{name} eq $srv } @{$all_server};

    if ( exists $srv_object->{auth} ) {
      if ( exists $srv_object->{auth}->{auth_type} ) {
        $ENV{REX_AUTH_TYPE} = $srv_object->{auth}->{auth_type};
      }

      if ( exists $srv_object->{auth}->{public_key} ) {
        $ENV{REX_PUBLIC_KEY} = $srv_object->{auth}->{public_key};
      }

      if ( exists $srv_object->{auth}->{private_key} ) {
        $ENV{REX_PRIVATE_KEY} = $srv_object->{auth}->{private_key};
      }

      if ( exists $srv_object->{auth}->{user} ) {
        $ENV{REX_USER} = $srv_object->{auth}->{user};
      }

      if ( exists $srv_object->{auth}->{password} ) {
        $ENV{REX_PASSWORD} = $srv_object->{auth}->{password};
      }

      if ( exists $srv_object->{auth}->{sudo_password} ) {
        $ENV{REX_SUDO_PASSWORD} = $srv_object->{auth}->{sudo_password};
      }

      if ( exists $srv_object->{auth}->{sudo} ) {
        $ENV{REX_SUDO} = $srv_object->{auth}->{sudo};
      }

    }

    $ENV{JOBCONTROL_PROJECT_PATH} = $self->project->project_path;

    my $child_exit_status;
    chwd $rex_path, sub {
      my ( $chld_out, $chld_in, $pid );

      $self->project->app->log->debug(
        "Writing output to: $ENV{JOBCONTROL_EXECUTION_PATH}/output.log");

      my $out_fh =
        IO::File->new( "$ENV{JOBCONTROL_EXECUTION_PATH}/output.log", "a+" );
      my $err_fh =
        IO::File->new( "$ENV{JOBCONTROL_EXECUTION_PATH}/output.log", "a+" );
      capture {
        system( $self->project->app->config->{rex},
          '-H', $srv, '-t', 1, '-F', '-c', '-m',
          ( $cmdb ? ( '-O', "cmdb_path=$cmdb/jobcontrol.yml" ) : () ), $task );

        $child_exit_status = $?;
      }
      stdout => $out_fh, stderr => $err_fh;

    };

    if ( $child_exit_status == 0 ) {
      push @ret,
        {
        server  => $srv,
        rexfile => $self->name,
        task    => $task,
        status  => "success",
        };
    }
    else {
      push @ret,
        {
        server  => $srv,
        rexfile => $self->name,
        task    => $task,
        status  => "failed",
        };
    }

    if ( $child_exit_status != 0 && $job->fail_strategy eq "terminate" ) {
      $ret[-1]->{terminate_message} =
        "Terminating execution due to terminate fail strategy.";
    }

  }

  return \@ret;
}

1;
