#!/bin/bash
trap "echo I ALWAYS WIN" SIGINT SIGTERM
echo "term_trap.sh started"
(sleep 25; echo "Hello World") &
echo "pid is $$"

while :
do
        echo "b"
        sleep 1
done
