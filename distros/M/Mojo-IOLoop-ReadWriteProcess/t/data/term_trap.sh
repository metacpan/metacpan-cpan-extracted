#!/bin/bash
(sleep 25; echo "Hello World") &
trap "echo I ALWAYS WIN" SIGINT SIGTERM
echo "pid is $$"

while :
do
        echo "b"
        sleep 1
done
