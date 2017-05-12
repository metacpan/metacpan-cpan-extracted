package RWDE::Web::AppServer;

use strict;
use warnings;

use Sys::Syslog qw(:macros);

use RWDE::Configuration;
use RWDE::Logger;

use base qw(Net::Server::PreFork);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 531 $ =~ /(\d+)/;

$SIG{__WARN__} = \&errorHandler;

sub Launch {
  my ($self, $params) = @_;
  my $pidfile = '/var/run/' . lc(RWDE::Configuration->ServiceName) . '.pid';

  my $server = $self->new(
    {
      host                       => RWDE::Configuration->AppServerAddr,
      port                       => RWDE::Configuration->AppServerPort,
      setsid                     => 1,     # make process background itself and detach from terminal
      pid_file                   => $pidfile,
      user                       => 'httpd',
      group                      => 'httpd',
      log_file                   => 'Sys::Syslog',
      syslog_ident               => lc(RWDE::Configuration->ServiceName),
      syslog_logopt              => 'cons,pid',                             # match RWDE::Logger
      syslog_facility            => LOG_LOCAL0,
      log_level                  => 4,
      no_close_by_child          => 1,                                      # don't want child exit to cause shutdown
      leave_children_open_on_hup => 1,                                      # let child finish processing on restart

      #keep no spare servers under Debug - this prevents spare servers with old code from serving
      min_spare_servers => RWDE::Configuration->Debug ? 0 : 2,
      max_spare_servers => RWDE::Configuration->Debug ? 0 : 10,

      #only keep 1 server around under Debug - this forces a new server to be spawned for every serve
      min_servers  => RWDE::Configuration->Debug ? 1 : 5,
      max_servers  => RWDE::Configuration->Debug ? 1 : 50,
      max_requests => RWDE::Configuration->Debug ? 1 : 50,
    }
  );

  $server->run();

  return $server;
}

sub process_request {
  my $self = shift;

  return throw RWDE::DevelException({ info => 'Process_request has to be overriden' });
}

sub errorHandler {
  my $msg = shift;

  RWDE::Logger->syslog_msg('devel', $msg);

  return;
}

1;

