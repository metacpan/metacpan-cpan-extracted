#!/bin/bash
#
# mogilefuse  This shell script controls a MogileFS Fuse filesystem
#
# chkconfig:    - 97 03
#
# description:  mount/unmount script for MogileFS Fuse filesystem
# processname:  mogilefuse
#

# source function library
. /etc/rc.d/init.d/functions

PROCESSNAME=mount-mogilefs
MOUNTOPTS="--mountopt allow_other --domain www.example.com"
MOUNTPATH=/tmp/example.com
USER=example
RETVAL=0

start() {
	echo -n $"Starting MogileFS tracker daemon: "
	daemon --user $USER $PROCESSNAME --daemon $MOUNTOPTS -- $MOUNTPATH
	RETVAL=$?
	echo
}

stop() {
	echo -n $"Unmounting MogileFS Fuse filesystem: "
	fusermount -u $MOUNTPATH
	RETVAL=$?
	[ $RETVAL -eq 0 ] && success $"$base shutdown" || failure $"$base shutdown"
	echo
}

restart() {
	stop
	start
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart|force-reload|reload)
		restart
		;;
	condrestart)
		[ -f /var/lock/subsys/mogilefuse ] && restart
		;;
	status)
		status mogilefuse
		RETVAL=$?
		;;
	*)
		echo $"Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
		exit 1
esac

exit $RETVAL
