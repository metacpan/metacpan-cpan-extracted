#!/bin/sh
IP=$1
lftp -c "set net:timeout 5; set net:max-retries 1; set net:reconnect-interval-base 2; open $IP; ls;quit"

