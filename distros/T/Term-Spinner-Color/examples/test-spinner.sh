#!/bin/sh

printf "Doot doot                   "
../bin/spinner &
PID=$!
sleep 5
kill $PID
printf "DONE!"
echo
