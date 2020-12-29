#!/bin/sh

for F in *.cgi
do
  echo $F
  podselect $F > $F.pod
done
