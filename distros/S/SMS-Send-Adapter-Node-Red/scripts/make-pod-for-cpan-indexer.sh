#!/bin/sh

for F in *.cgi *.psgi
do
  echo $F
  podselect $F > $F.pod
done
