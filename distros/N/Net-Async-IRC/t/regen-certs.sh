#!/bin/sh
openssl genrsa -out privkey.pem 
openssl req -new -x509 -key privkey.pem -out server.pem 
