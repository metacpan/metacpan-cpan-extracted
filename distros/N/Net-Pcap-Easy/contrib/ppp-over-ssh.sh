#/bin/sh

pppd updetach noauth passive pty \
    "ssh ${SERVER_HOSTNAME:-razor} -o Batchmode=yes pppd nodetach notty noauth" \
    ipparam vpn 10.1.1.1:10.1.1.2

