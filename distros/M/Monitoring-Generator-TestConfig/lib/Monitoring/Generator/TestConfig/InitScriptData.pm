package # hidden from cpan
    Monitoring::Generator::TestConfig::InitScriptData;

use strict;
use warnings;

########################################

=over 4

=item get_init_script

    returns the init script source

    adapted from the nagios debian package

=back

=cut

sub get_init_script {
    my $self      = shift;
    my $prefix    = shift;
    my $binary    = shift;
    my $user      = shift;
    my $group     = shift;
    my $layout    = shift;
    our $initsource;
    if(!defined $initsource) {
       while(my $line = <DATA>) { $initsource .= $line; }
    }

    my $initscript = $initsource;
    $initscript =~ s/__PREFIX__/$prefix/gmx;
    $initscript =~ s/__BINARY__/$binary/gmx;
    $initscript =~ s/__USER__/$user/gmx;
    $initscript =~ s/__GROUP__/$group/gmx;
    $initscript =~ s/__LAYOUT__/$layout/gmx;
    return($initscript);
}

1;

__DATA__
#!/bin/sh
#
### BEGIN INIT INFO
# Provides:          __LAYOUT__
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: __LAYOUT__ network monitor
# Description:       Start and stop the __LAYOUT__ test config
### END INIT INFO
#
# Original Author : Jorge Sanchez Aymar (jsanchez@lanchile.cl)

status___LAYOUT__ () {
	if ps -p $PID > /dev/null 2>&1; then
	        return 0
	else
		return 1
	fi

	return 1
}


printstatus___LAYOUT__() {
	if status___LAYOUT__ $1 $2; then
		echo "__LAYOUT__ (pid $PID) is running..."
	else
		echo "__LAYOUT__ is not running"
	fi
}


killproc___LAYOUT__ () {
	kill $2 $PID

}


pid___LAYOUT__ () {
	if test ! -f $RunFile; then
		echo "No lock file found in $RunFile"
		exit 1
	fi

	PID=`head -n 1 $RunFile`
}


# Source function library
# Solaris doesn't have an rc.d directory, so do a test first
if [ -f /etc/rc.d/init.d/functions ]; then
	. /etc/rc.d/init.d/functions
elif [ -f /etc/init.d/functions ]; then
	. /etc/init.d/functions
fi

prefix=__PREFIX__
Bin=__BINARY__
CfgFile=${prefix}/__LAYOUT__.cfg
StatusFile=${prefix}/var/status.dat
RetentionFile=${prefix}/var/retention.dat
CommandFile=${prefix}/var/rw/__LAYOUT__.cmd
VarDir=${prefix}/var
RunFile=${prefix}/var/__LAYOUT__.pid
LockDir=${prefix}/var/
LockFile=__LAYOUT__.pid
User=__USER__
Group=__GROUP__


# Check that our binary exists.
if [ ! -f $Bin ]; then
    echo "Executable file $Bin not found.  Exiting."
    exit 1
fi

# Check that main configuration exists.
if [ ! -f $CfgFile ]; then
    echo "Configuration file $CfgFile not found.  Exiting."
    exit 1
fi

# See how we were called.
case "$1" in

	start)
		echo -n "Starting __LAYOUT__:"
		$Bin -v $CfgFile > /dev/null 2>&1;
		if [ $? -eq 0 ]; then
			touch $VarDir/__LAYOUT__.log $RetentionFile
			rm -f $CommandFile
			touch $RunFile
			#chown $User:$Group $RunFile
			$Bin -d $CfgFile
			if [ -d $LockDir ]; then touch $LockDir/$LockFile; fi
			echo " done."
			exit 0
		else
			echo "CONFIG ERROR!  Start aborted.  Check your configuration."
			exit 1
		fi
		;;

	stop)
		echo -n "Stopping __LAYOUT__: "

		pid___LAYOUT__
		killproc___LAYOUT__ $Bin

 		# now we have to wait for the process to exit and remove its
 		# own RunFile, otherwise a following "start" could
 		# happen, and then the exiting process will remove the
 		# new RunFile, allowing multiple daemons
 		# to (sooner or later) run - John Sellens
		#echo -n 'Waiting for __LAYOUT__ to exit .'
 		for i in 1 2 3 4 5 6 7 8 9 10 ; do
 		    if status___LAYOUT__ > /dev/null; then
 			echo -n '.'
 			sleep 1
 		    else
 			break
 		    fi
 		done
 		if status___LAYOUT__ > /dev/null; then
 		    echo ''
 		    echo 'Warning - __LAYOUT__ did not exit in a timely manner'
 		else
 		    echo 'done.'
 		fi

		rm -f $StatusFile $RunFile $LockDir/$LockFile $CommandFile
		;;

	status)
		pid___LAYOUT__
		printstatus___LAYOUT__ $Bin
		;;

	check|checkconfig)
		printf "Running configuration check..."
		$Bin -v $CfgFile
		if [ $? -eq 0 ]; then
			echo " OK."
		else
			echo " CONFIG ERROR!  Check your __LAYOUT__ configuration."
			exit 1
		fi
		;;

	restart)
		printf "Running configuration check..."
		$Bin -v $CfgFile > /dev/null 2>&1;
		if [ $? -eq 0 ]; then
			echo "done."
			$0 stop
			$0 start
		else
			echo " CONFIG ERROR!  Restart aborted.  Check your __LAYOUT__ configuration."
			exit 1
		fi
		;;

	reload|force-reload)
		printf "Running configuration check..."
		$Bin -v $CfgFile > /dev/null 2>&1;
		if [ $? -eq 0 ]; then
			echo "done."
			if test ! -f $RunFile; then
				$0 start
			else
				pid___LAYOUT__
				if status___LAYOUT__ > /dev/null; then
					printf "Reloading __LAYOUT__ configuration..."
					killproc___LAYOUT__ $Bin -HUP
					echo "done"
				else
					$0 stop
					$0 start
				fi
			fi
		else
			echo " CONFIG ERROR!  Reload aborted.  Check your __LAYOUT__ configuration."
			exit 1
		fi
		;;

	*)
		echo "Usage: __LAYOUT__ {start|stop|restart|reload|force-reload|status|checkconfig}"
		exit 1
		;;

esac

# End of this script
