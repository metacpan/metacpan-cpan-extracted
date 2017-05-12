#!/bin/sh

TIMEOUT=$1

if [ -z "$TIMEOUT" ];  then
	echo "No timeout given, won't sleep"
	exit 0
fi

echo "Sleeping for $TIMEOUT seconds"
sleep $TIMEOUT
exit 0
