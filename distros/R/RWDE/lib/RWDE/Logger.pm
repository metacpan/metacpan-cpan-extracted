package RWDE::Logger;

use strict;
use warnings;

use Error qw(:try);
use Sys::Syslog qw(:standard :extended :macros);

use RWDE::Configuration;
use RWDE::Exceptions;

our ($debug, $syslog_socket);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::Logger

Provides methods to log via syslog

=cut

=head2 set_debug()

Method to enable debug mode 

=cut

sub set_debug {
  $debug = 1;
  return;
}

=head2 toggle_debug()

Method to toggle debug mode

=cut

sub toggle_debug {
  $debug = ($debug ? 0 : 1);
  return;
}

=head2 is_debug()

Determine if debug mode is currently set

=cut

sub is_debug {
  return $debug;
}

=head2 _init_syslog()

Private Method

Open the syslog connection defined within the Configuration file

=cut

sub _init_syslog {

  # open syslog connection
  my $result = setlogsock 'unix';

  if (not defined $result) {
    throw RWDE::DevelException({ info => 'Could not connect to syslog facility' });
  }

  $syslog_socket = $result;

  my $log_filename = lc(RWDE::Configuration->ServiceName);
  openlog($log_filename, 'cons,pid', LOG_LOCAL0);

  return ();
}

=head2 syslog_msg()

Log a message to syslog via the established syslog connection

A type and info are required

type is one of debug, info, notice, warning, err, crit, alert, emerg
info is the desired log message

=cut

sub syslog_msg {
  my ($self, $type, $info) = @_;

  if (!($syslog_socket)) {
    _init_syslog();
  }

  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);

  my %valid_level = (
    debug   => 1,
    info    => 1,
    notice  => 1,
    warning => 1,
    err     => 1,
    crit    => 1,
    alert   => 1,
    emerg   => 1
  );

  if (not defined $valid_level{$type}) {
    $type = 'info';
  }

  if (not defined $info) {
    my ($package, $filename, $line) = caller(1);
    $info = "No message sent to syslog from $filename Line: $line!";
  }

  if (defined($package) && defined($subroutine)) {
    $info = "$package=>$subroutine ($info)";
  }

  syslog($type, '%s', $info);

  debug_info($type, $info);

  return;
}

=head2 debug_info()

Take the type and the human readable message and print it to STDERR if debug is on

=cut

sub debug_info {
  my ($type, $info) = @_;

  if ($debug) {
    my $d = scalar localtime;
    print "$d: $type -- $info\n";
  }

  return ();
}

1;
