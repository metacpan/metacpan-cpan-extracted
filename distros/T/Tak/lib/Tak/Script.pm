package Tak::Script;

use Getopt::Long qw(GetOptionsFromArray :config posix_defaults bundling);
use Config::Settings;
use IO::Handle;
use Tak::Client::Router;
use Tak::Client::RemoteRouter;
use Tak::Router;
use Log::Contextual qw(:log);
use Log::Contextual::SimpleLogger;
use Moo;

with 'Tak::Role::ScriptActions';

has options => (is => 'ro', required => 1);
has env => (is => 'ro', required => 1);

has log_level => (is => 'rw');

has stdin => (is => 'lazy');
has stdout => (is => 'lazy');
has stderr => (is => 'lazy');

sub _build_stdin { shift->env->{stdin} }
sub _build_stdout { shift->env->{stdout} }
sub _build_stderr { shift->env->{stderr} }

has config => (is => 'lazy');

sub _build_config {
  my ($self) = @_;
  my $file = $self->options->{config} || '.tak/default.conf';
  if (-e $file) {
    Config::Settings->new->parse_file($file);
  } else {
    {};
  }
}

has local_client => (is => 'lazy');

sub _build_local_client {
  my ($self) = @_;
  Tak::Client::Router->new(service => Tak::Router->new);
}

sub BUILD {
  shift->setup_logger;
}

sub setup_logger {
  my ($self) = @_;
  my @level_names = qw(fatal error warn info debug trace);
  my $options = $self->options;
  my $level = 2 + ($options->{verbose}||0) - ($options->{quiet}||0);
  my $upto = $level_names[$level];
  $self->log_level($upto);
  Log::Contextual::set_logger(
    Log::Contextual::SimpleLogger->new({
      levels_upto => $upto,
      coderef => sub { print STDERR '<local> ', @_ },
    })
  );
}

sub _parse_options {
  my ($self, $string, $argv) = @_;
  my @spec = split ';', $string;
  my %opt;
  GetOptionsFromArray($argv, \%opt, @spec);
  return \%opt;
}

sub run {
  my ($self) = @_;
  my @argv = @{$self->env->{argv}};
  unless (@argv && $argv[0]) {
    return $self->local_help;
  }
  my $cmd = shift(@argv);
  $cmd =~ s/-/_/g;
  if (my $code = $self->can("local_$cmd")) {
    return $self->_run($cmd, $code, @argv);
  } elsif ($code = $self->can("each_$cmd")) {
    return $self->_run_each($cmd, $code, @argv);
  } elsif ($code = $self->can("every_$cmd")) {
    return $self->_run_every($cmd, $code, @argv);
  }
  $self->stderr->print("No such command: ${cmd}\n");
  return $self->local_help;
}

sub _load_file {
  my ($self, $file) = @_;
  $self->_load_file_in_my_script($file);
}

sub local_help {
  my ($self) = @_;
  $self->stderr->print("Help unimplemented\n");
}

sub _maybe_parse_options {
  my ($self, $code, $argv) = @_;
  if (my $proto = prototype($code)) {
    $self->_parse_options($proto, $argv);
  } else {
    {};
  }
}

sub _run_local {
  my ($self, $cmd, $code, @argv) = @_;
  my $opt = $self->_maybe_parse_options($code, \@argv);
  $self->$code($opt, @argv);
}

sub _run_each {
  my ($self, $cmd, $code, @argv) = @_;
  my @targets = $self->_host_list_for($cmd);
  unless (@targets) {
    $self->stderr->print("No targets for ${cmd}\n");
    return;
  }
  my $opt = $self->_maybe_parse_options($code, \@argv);
  $self->local_client->ensure(connector => 'Tak::ConnectorService');
  foreach my $target (@targets) {
    my $remote = $self->_connection_to($target);
    $self->$code($remote, $opt, @argv);
  }
}

sub _run_every {
  my ($self, $cmd, $code, @argv) = @_;
  my @targets = $self->_host_list_for($cmd);
  unless (@targets) {
    $self->stderr->print("No targets for ${cmd}\n");
    return;
  }
  my $opt = $self->_maybe_parse_options($code, \@argv);
  $self->local_client->ensure(connector => 'Tak::ConnectorService');
  my @remotes = map $self->_connection_to($_), @targets;
  $self->$code(\@remotes, $opt, @argv);
}

sub _host_list_for {
  my ($self, $command) = @_;
  my @host_spec = map split(' ', $_), @{$self->options->{host}};
  unshift(@host_spec, '-') if $self->options->{local};
  return @host_spec;
}

sub _connection_to {
  my ($self, $target) = @_;
  log_debug { "Connecting to ${target}" };
  my @path = $self->local_client->do(
    connector => create => $target, log_level => $self->log_level
  );
  my ($local, $remote) =
    map $self->local_client->curry(connector => connection => @path => $_),
      qw(local remote);
  $local->ensure(module_sender => 'Tak::ModuleSender');
  $remote->ensure(
    module_loader => 'Tak::ModuleLoader',
    expose => { module_sender => [ 'remote', 'module_sender' ] }
  );
  $remote->do(module_loader => 'enable');
  log_debug { "Setup connection to ${target}" };
  Tak::Client::RemoteRouter->new(
    %$remote, host => $target
  );
}

1;
