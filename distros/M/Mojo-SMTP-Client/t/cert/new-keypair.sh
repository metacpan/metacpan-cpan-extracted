#!/usr/bin/env bash

openssl req -x509 -config openssl.cnf -newkey rsa:4096 -keyout server.key -out server.crt -days 10000 -nodes
