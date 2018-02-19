#!/bin/bash

wd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
die() { echo "$*" 1>&2 ; exit 1; }

$wd/dead_master.sh &
$wd/spawn.sh &
die "roulette KaBoom"
