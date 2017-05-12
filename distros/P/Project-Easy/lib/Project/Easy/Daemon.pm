package Project::Easy::Daemon;

use Class::Easy;
use IO::Easy;

use POSIX ();

use Project::Easy::Config;

has 'pid_file';
has 'code';

sub new {
	my $class  = shift;
	my $core   = shift;
	my $code   = shift;
	my $config = shift;
	
	my $root = $core->root;
	my $id   = $core->id;
	
	if (defined $config->{pid_file}) {
		$config->{pid_file} = file ($config->{pid_file});
	} else {
		
		$config->{pid_file} = $root->file_io ('var', 'run', $id . '-' . $code . '.pid');
	}
	
	if (defined $config->{log_file}) {
		$config->{log_file} = file ($config->{log_file});
	} else {
		$config->{log_file} = $root->file_io ('var', 'log', $id . '-' . $code . '_log');
	}
	
	$config->{code} = $code;
	
	bless $config, $class;
}

sub startup_script {
	my $self = shift;
	
	
}

sub create_script_file {
	my $self = shift;
	my $root = shift;
	
	my $script = $root->file_io ('bin', 'daemon_'.$self->code);
	
	my $data_files = file->__data__files ();
	
	my $script_text = Project::Easy::Config::string_from_template (
		$data_files->{script},
		{
			daemon_code => $self->code
		}
	);
	
	$script->store ($script_text);
}

sub launch {
	my $self = shift;
	
	if ($self->{package}) {
		
		if ($self->{user}) {
			my $uid = $self->{user};
			$uid = (getpwnam ($self->{user})) [2]
				if $self->{user} !~ /^\d+$/;
			
			POSIX::setuid ($uid)
				if defined $uid and $uid;
		}

		if ($self->{group}) {
			my $gid = $self->{group};
			$gid = (getgrnam ($self->{group})) [2]
				if $self->{group} !~ /^\d+$/;
			
			POSIX::setgid ($gid)
				if defined $gid and $gid;
		}
		
		my $ppid = fork();

		if (not defined $ppid) {
			print "resources not avilable.\n";
		} elsif ($ppid == 0) {
			# exit(0);
			die "cannot detach from controlling terminal"
				if POSIX::setsid() < 0;

			my $log_fh;

			my $pid_file = $self->{pid_file};
			$pid_file->store ($$);
			
			die 'cannot open log file to append'
				unless open $log_fh, '>>', $self->{log_file}->path;

			# DIRTY
			$SIG{__WARN__} = sub {
				print $log_fh @_;
			};
			$SIG{__DIE__} = sub {
				print $log_fh @_;
			};

			my $previous_default = select ($log_fh);
			$|++;
			select ($previous_default);

			close STDOUT;
			close STDERR;
			close STDIN;
			
			if ($self->can ('_launched')) {
				$self->_launched;
			}

		} else {
			exit (0);
		}
	
	} elsif ($self->{bin}) {
		# DEPRECATED
		my $conf_file = $self->{conf_file};
		my $httpd_bin = $self->{bin};
		print "starting daemon by: $httpd_bin -f $conf_file\n";
		`$httpd_bin -f $conf_file`;
		
	} else {
		die "you must define daemon package or bin file";
	}
	
	
	sleep 1;
	
	warn "not running"
		unless $self->running;
}

sub running {
	my $self = shift;
	
	my $pid = $self->pid;
	
	return 0 unless defined $pid;
	
	if ($^O eq 'darwin') {
		my $ps = `ps -x -p $pid -o rss=,command=`;
		if ($ps =~ /^\s+(\d+)\s+(.*)$/m) {
			return 1;
		}
	} else {
		return kill 0, $pid;
	}
}

sub pid {
	my $self = shift;
	
	my $pid;
	if (-f $self->pid_file) {
		$pid = $self->pid_file->contents;
	}
	
	return unless defined $pid;
	
	return unless $pid =~ /(\d+)/;
	
	return $1;
}

sub shutdown {
	my $self = shift;
	
	my $pid = $self->pid;
	
	return 1 unless defined $pid; 
	
	kill 15, $pid;

	my $count = 10;
	
	for (1..$count) {
		print ($count + 1 - $_ ."… ");
		sleep 1;
		# wait one more second
		unless ($self->running) {
			unlink $self->pid_file;
			return 1;
		}
	}

	print "kill with force\n";

	kill 9, $pid;
	
	for (1..$count) {
		print ($count + 1 - $_ ."… ");
		sleep 1;
		# wait one more second
		unless ($self->running) {
			unlink $self->pid_file;
			return 1;
		}
	}
	
	return 0;
}

sub process_command {
	my $self = shift;
	my $comm = shift;
	
	if ($comm eq 'stop') {
		if (! $self->running) {
			print "no process is running\n";
			exit;
		}
		
		print "awaiting process to kill… ";
		$self->shutdown;
		
		print "\n";
	
	} elsif ($comm eq 'start') {
		if ($self->running) {
			print "no way, process is running\n";
			exit;
		}
		
		$self->launch;
		
	} elsif ($comm eq 'restart') {
		if ($self->running) {
			my $finished = $self->shutdown;
			
			unless ($finished) {
				print "pid is running after kill, please kill manually\n";
				exit;
			}
		}
		
		$self->launch;
	}
	
}

sub TO_JSON {
	my $self = shift;
	
	my $result = {map {$_ => $self->{$_}} keys %$self};
	$result->{pid_file} = $result->{pid_file}->path;
	$result->{log_file} = $result->{log_file}->path;
	
	$result;
}

1;

__DATA__

########################
# IO::Easy script
########################

#!/usr/bin/env perl

use Project::Easy qw(script);

use Getopt::Long qw(:config auto_version auto_help);

my $o = {
	verbose => '',
	detach  => 1
};

GetOptions (
	$o,
	'verbose!',
	'detach!'
);

my $command = $ARGV[0];

my $instance = $::project->instance;

print "project '".$::project->id."' using instance: '$instance'\n";

Project::Easy::Helper::status ();

# die $o->{verbose};

if ($o->{verbose}) {
	logger (default => *STDERR);
}

my $launch_method = 'launch';
unless ($o->{detach}) {
	$launch_method = '_launched';
}

my $daemon = $::project->daemon ('{$daemon_code}');

print 'process id ' . ($daemon->pid || '[undef]') . ' is' . (
	$daemon->running
	? ''
	: ' not'
) . " running\n";

exit unless $command;

$daemon->process_command ($command);

########################
# IO::Easy startup.linux
########################

#!/bin/sh
. /etc/rc.status

PROJ="{$id}"

SU_USER="{$daemon-user}"
SU_GROUP="{$daemon-group}"
{$daemon-env}
DAEMON_CMD="{$project-root}/bin/{$daemon-script}"
DAEMON_PIDFILE="{$daemon-pid}"
DAEMON_FLAGS="{$daemon-flags}"

# [ "$DAEMON_PIDFILE" ] || { echo "No directive PidFile: \$DAEMON_PIDFILE"; exit 1; }
[ -f "$DAEMON_PIDFILE" ] && DAEMON_PID=$(cat "$DAEMON_PIDFILE")

RETVAL=0

perform_daemon() {
	DAEMON_OPERATION=$1
	DAEMON_OPERATION_MSG=`echo $DAEMON_OPERATION | tr [a-z] [A-Z]`
	
	echo -n $DAEMON_OPERATION_MSG $DAEMON_CMD ": "
	
	_CMD="su - $SU_USER -c"
	
	if [ "$SU_USER" ] && [ $(id -un) = "$SU_USER" ]; then _CMD="sh -c" ; fi
	
	$($CMD "eval $var; $DAEMON_CMD $DAEMON_OPERATION $DAEMON_FLAGS")

	rc_status -v
	RETVAL=$?
}
	
case "$1" in
	start)
	stop)
	restart)
	status)
		perform_daemon $1
	;;
	forcestop)
		echo -n "Force stop: $DAEMON_CMD"
		pkill -f "$DAEMON_CMD" >/dev/null 2>&1
		rc_status -v
		RETVAL=$?
	;;
	*)
		echo "${0##*/} {start|stop|forcestop|restart|status}"
		RETVAL=1
esac

exit $RETVAL

########################
# IO::Easy startup.darwin
########################

FILE2 CONTENTS