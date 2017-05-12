#!/bin/sh

USER=$1
PASS=$2
WGET="wget -q -O /dev/null"

if $WGET http://${USER}:${PASS}@localhost:3000/auth ; then
  echo "$USER is authenticate"
else
  echo "AUTH FAILED"
fi

if $WGET http://localhost:3000/authz/user/${USER}/GET/some/user/resource ; then
  echo "$USER is authorized to GET /some/user/resource"
else
  echo "AUTHZ FAILED"
fi
