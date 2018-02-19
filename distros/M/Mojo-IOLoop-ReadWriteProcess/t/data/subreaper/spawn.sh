#!/bin/bash

sleep 3

wd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $wd
die() { echo "$*" 1>&2 ; exit 1; }

$wd/child.sh &
$wd/child.sh &

die "spawner: 2 Boom"
