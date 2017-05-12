#!/bin/sh

case "$1" in
	start)
		if [ -x /usr/local/sbin/foundry-cvs2svn ]; then
			/usr/local/sbin/foundry-cvs2svn 60 &
			echo -n ' foundry-cvs2svn'
		fi
		if [ -x /usr/local/sbin/foundry-syncdata ]; then
			/usr/local/sbin/foundry-syncdata 60 &
			echo -n ' foundry-syncdata'
		fi
		;;
	stop)
		if [ -f /tmp/foundry/cvs2svn.lock ]; then
			/bin/kill `cat /tmp/foundry/cvs2svn.lock` > /dev/null 2>&1 && echo -n ' foundry-cvs2svn'
		else
			echo "foundry-cvs2svn isn't running"
		fi
		if [ -f /tmp/foundry/syncdata.lock ]; then
			/bin/kill `cat /tmp/foundry/syncdata.lock` > /dev/null 2>&1 && echo -n ' foundry-syncdata'
		else
			echo "foundry-syncdata isn't running"
		fi
		;;
	*)
		echo ""
		echo "Usage: `basename $0` { start | stop }"
		echo ""
		exit 64
		;;
esac
