#!/bin/sh

# Generates self-signed certificate
# Edit openssl.conf before running this

KEYFILE=server.key
CERTFILE=server.crt

openssl req -new -x509 -nodes -config openssl.conf -out $CERTFILE -keyout $KEYFILE -days 36500 || exit 2
chmod 0600 $KEYFILE
echo 
openssl x509 -subject -fingerprint -noout -in $CERTFILE || exit 2
