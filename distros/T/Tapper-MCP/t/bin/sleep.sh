#!/bin/bash

export SLEEP_TIME=${1:-10}

echo "1..2"
echo "ok - sleep"
sleep $SLEEP_TIME
echo "ok - wake up"
