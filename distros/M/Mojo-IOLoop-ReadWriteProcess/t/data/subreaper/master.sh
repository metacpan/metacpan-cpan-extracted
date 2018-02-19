#!/bin/bash

sleep 1

wd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $wd
echo "master"
$wd/child.sh &
$wd/spawn.sh &
$wd/child.sh &
$wd/child.sh &
$wd/child.sh &

echo "done"
