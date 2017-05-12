package Mojo::Command::Generate::InitScript::Debian;

use warnings;
use strict;
use File::Spec;

#use base 'Mojo::Command::Generate::InitScript::Base';
use base 'Mojo::Command';
use Getopt::Long 'GetOptions';
use File::Spec;
use IO::File;
use List::Util qw(first);

__PACKAGE__->attr(usage => <<"EOF");
Debian initscript related options:
    --should-start <applist>    defines facilities which, if present, 
                                should be available during startup of this service    
    --should-stop <applist>     facilities which should be available 
                                during shutdown of this service.
    --runlevels  <runlevels>    which run levels should by default run the init script
                                with a start (stop) argument to start (stop)
                                (Default: 2 3 4 5)
EOF

sub run
{
	my ( $self, $opt ) = @_;

	$opt->{'should-start'} = [];
	$opt->{'should-stop'}  = [];
	$opt->{'runlevels'}    = [2, 3, 4, 5];
	$opt->{'stoplevels'}   = [];

	GetOptions($opt,
		'should-start=s{,}', 'should-stop=s{,}', 'runlevels=i{,}',
	);

	for my $i (0..6)
	{
		if ( !first { $i == $_ } @{ $opt->{'runlevels'} } )
		{
			push @{ $opt->{'stoplevels'} }, $i;
		}
	}

	# init script
	my $file = $opt->{'deploy'}
				? '/etc/init.d/'. $opt->{'name'}
				: File::Spec->join($opt->{'output'}, $opt->{'name'});
	$self->render_to_file( 'initscript', $file, $opt );
	$self->chmod_file( $file, 0755 );

	# config file
	$file = $opt->{'deploy'}
				? '/etc/default/'. $opt->{'name'}
				: File::Spec->join($opt->{'output'}, 'etc_default_'.$opt->{'name'});
	$self->render_to_file( 'config', $file, $opt );
	$self->chmod_file( $file, 0644 );

	if ( $opt->{'deploy'} )
	{
		system('/usr/sbin/update-rc.d', $opt->{'name'},
			'start', '20', (@{ $opt->{'runlevels'} }), '.',
			'stop', '20', (@{ $opt->{'stoplevels'} }), '.'
		);
	}
}
1;
__DATA__
@@ initscript
% my $opt = shift;
% my $name = $opt->{'name'};
#! /bin/sh

### BEGIN INIT INFO
# Provides:          <%= $name %>
# Required-Start:    $remote_fs $local_fs $network $syslog $time
# Required-Stop:     $remote_fs $local_fs $network $syslog $time
% if ( @{ $opt->{'should-start'} } )
% {
# Should-Start:      <%= join(' ', @{ $opt->{'should-start'} } ) %>
% }
% if ( @{ $opt->{'should-stop'} } )
% {
# Should-Stop:       <%= join(' ', @{ $opt->{'should-stop'} } ) %>
% }
# Default-Start:     <%= join(' ', @{ $opt->{'runlevels'} } ) %>
# Default-Stop:      <%= join(' ', @{ $opt->{'stoplevels'} } ) %>
# Short-Description: starts <%= $name %> application
# Description:       starts <%= $name %> application
### END INIT INFO

set -e

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=<%= $opt->{'app_script'} %>
NAME=<%= $name %>
DESC=<%= $name %>

MODE="daemon_prefork"
PIDFILE="/var/run/<%= $name %>.pid"
EXTRA_ARGS=""
USER="nobody"

# Include nginx defaults if available
if [ -f /etc/default/<%= $name %> ] ; then
        . /etc/default/<%= $name %>
fi

DAEMON_ARGS="$MODE --daemonize --pid $PIDFILE --user $USER $EXTRA_ARGS"

. /lib/lsb/init-functions

do_start() {
		start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_ARGS
}

do_stop() {
		start-stop-daemon --stop --quiet --pidfile $PIDFILE
}

case "$1" in
	start)
		log_daemon_msg "Starting $DESC" "$NAME"
		do_start
		log_end_msg $?
		;;
	stop)
		log_daemon_msg "Stopping $DESC" "$NAME"
		do_stop
		log_end_msg $?
		;;
	restart|force-reload)
		log_daemon_msg "Restarting $DESC" "$NAME"
		do_stop
		do_start
		log_end_msg $?
		;;
	status)
		status_of_proc -p $PIDFILE $DAEMON $NAME && exit 0 || exit $?
		;;
	*)
		echo "Usage: $NAME {start|stop|restart|force-reload|status}" >&2
		exit 1
		;;

esac

exit 0

@@ config
% my $opt = shift;
% my $name = $opt->{'name'};

MODE="daemon_prefork"
PIDFILE="/var/run/<%= $name %>.pid"
EXTRA_ARGS=""
USER="nobody"

__END__

=head1 NAME

Mojo::Command::Generate::InitScript::Debian - Initscript generator for Linux Debian

=head1 SYNOPSYS

	$ ./mojo_app.pl generate help init_script debian
	usage: ./mojo_app.pl generate init_script target_os [OPTIONS]

	These options are available:
		--output <folder>   Set folder to output initscripts
		--deploy            Deploy initscripts into OS
							Either --deploy or --output=dist should be specified

		--name <name>       Ovewrite name which is used for initscript filename(s)

	Debian initscript related options:
		--should-start <applist>    defines facilities which, if present,
									should be available during startup of this service
		--should-stop <applist>     facilities which should be available
									during shutdown of this service.
		--runlevels  <runlevels>    which run levels should by default run the init script
									with a start (stop) argument to start (stop)
									(Default: 2 3 4 5)

=cut
