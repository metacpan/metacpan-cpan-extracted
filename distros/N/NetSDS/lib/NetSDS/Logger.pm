#===============================================================================
#
#         FILE:  Logger.pm
#
#  DESCRIPTION:  Syslog wrapper for Net SDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.04.2008 17:32:37 EEST
#===============================================================================

=head1 NAME

NetSDS::Logger - syslog wrapper for applications and classes

=head1 SYNOPSIS

	use NetSDS::Logger;

	my $logger = NetSDS::Logger->new(
		name => 'NetSDS-SuperDaemon',
	);
	$logger->log("info", "Syslog message here");

=head1 DESCRIPTION

This module contains implementation of logging functionality for NetSDS components.

By default, messages are logged with C<local0> facility and C<pid,ndelay,nowait> options.

B<NOTE>: C<NetSDS::Logger> module is for internal use mostly from application
frameworks like C<NetSDS::App>, C<NetSDS::App::FCGI>, etc.

=cut

package NetSDS::Logger;

use 5.8.0;
use warnings;

use Unix::Syslog qw(:macros :subs);

use version; our $VERSION = '1.301';

#===============================================================================

=head1 CLASS API

=over

=item B<new(%parameters)> - constructor

Constructor B<new()> creates new logger object and opens socket with default
NetSDS logging parameters.

Arguments allowed (as hash):

B<name> - application name for identification

	Use only ASCII characters in "name" to avoid possible errors.
	Default value is "NetSDS".

B<facility> - logging facility

	Available facility values:

		* local0..local7
		* user
		* daemon

	If not set 'local0' is used as default value

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = {};

	# Set application identification name
	my $name = 'NetSDS';
	if ( $params{name} ) {
		$name = $params{name};
	}

	# Set logging facility
	my %facility_map = (
		'local0' => LOG_LOCAL0,
		'local1' => LOG_LOCAL1,
		'local2' => LOG_LOCAL2,
		'local3' => LOG_LOCAL3,
		'local4' => LOG_LOCAL4,
		'local5' => LOG_LOCAL5,
		'local6' => LOG_LOCAL6,
		'local7' => LOG_LOCAL7,
		'user'   => LOG_USER,
		'daemon' => LOG_DAEMON,
	);

	my $facility = LOG_LOCAL0;    # default is local0
	if ( $params{facility} ) {
		$facility = $facility_map{ $params{facility} } || LOG_LOCAL0;
	}

	openlog( $name, LOG_PID | LOG_CONS | LOG_NDELAY, $facility );

	return bless $self, $class;

} ## end sub new

#***********************************************************************

=item B<log($level, $message)> - write record to log

Wrapper to C<syslog()> method of L<Unix::Syslog> module.

Level is passed as string and may be one of the following:

	alert	- LOG_ALERT
	crit	- LOG_CRIT
	debug	- LOG_DEBUG
	emerg	- LOG_EMERG
	error	- LOG_ERR
	info	- LOG_INFO
	notice	- LOG_NOTICE
	warning	- LOG_WARNING

=cut

#-----------------------------------------------------------------------
sub log {

	my ( $self, $level, $message ) = @_;

	# Level aliases
	my %LEVFIX = (
		alert     => LOG_ALERT,
		crit      => LOG_CRIT,
		critical  => LOG_CRIT,
		deb       => LOG_DEBUG,
		debug     => LOG_DEBUG,
		emerg     => LOG_EMERG,
		emergency => LOG_EMERG,
		panic     => LOG_EMERG,
		err       => LOG_ERR,
		error     => LOG_ERR,
		inf       => LOG_INFO,
		info      => LOG_INFO,
		inform    => LOG_INFO,
		note      => LOG_NOTICE,
		notice    => LOG_NOTICE,
		warning   => LOG_WARNING,
		warn      => LOG_WARNING,
	);

	my $LEV = $LEVFIX{$level};

	if ( !$LEV ) {
		$LEV = LOG_INFO;
	}

	if ( !$message ) {
		$message = "";
	}

	syslog( $LEV, "[$level] $message" );

} ## end sub log

#***********************************************************************

=item B<DESTROY> - class destructor

Destructor (DESTROY method) calls C<closelog()> function. That's all.

=cut

#-----------------------------------------------------------------------
sub DESTROY {

	closelog();

}

1;

__END__

=back

=head1 EXAMPLES

See L<NetSDS::App> for example.

=head1 SEE ALSO

L<Sys::Syslog>

=head1 TODO

1. Implement logging via UDP socket.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

