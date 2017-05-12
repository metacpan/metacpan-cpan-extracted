#!/bin/bash
#
# bash script to manage Progra
# israel leiva <ilv@cpan.org>
#
# usage:
# chmod +x progra.sh
#	./progra [start|stop|restart]
#

DIR="/home/progra/"
SCRIPT_NAME="client.pl"
OPTION=$1

cd $DIR

if [ $OPTION = 'start' ]; then
	echo ":: starting progra"
	LS=$(ls *.pid 2>/dev/null)
	if [ "$LS" = "" ]; then
		perl $SCRIPT_NAME
	else
		echo "ERROR: progra is already running"
		echo "stop the old one before starting a new instance"
	fi
elif [ $OPTION = "stop" ]; then
	echo ":: stopping progra"
	LS=$(ls *.pid 2>/dev/null)
	if [ "$LS" = "" ]; then
		echo "ERROR: no progra running"
	else
		rm $LS
	fi
elif [ $OPTION = "restart" ]; then
	echo ":: restarting progra"
	LS=$(ls *.pid 2>/dev/null)
	if [ "$LS" = "" ]; then
		echo "ERROR: no progra running"
	else
		rm $LS
		sleep 2
		echo ":: starting progra"
		perl $SCRIPT_NAME
	fi
else
	echo ":: invalid option"
fi



