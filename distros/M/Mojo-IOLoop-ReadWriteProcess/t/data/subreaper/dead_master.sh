#/bin/sh

wd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $wd
die() { echo "$*" 1>&2 ; exit 1; }

sleep 2
$wd/dead_child.sh &
$wd/spawn.sh &

die " master 1Boom"
