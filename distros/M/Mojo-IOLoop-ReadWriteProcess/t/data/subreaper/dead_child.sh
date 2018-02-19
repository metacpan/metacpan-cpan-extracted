#!/bin/sh

sleep 3
die() { echo "$*" 1>&2 ; exit 1; }
die "dead child Boom"
