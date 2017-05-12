#!/bin/sh

rcdist=/home/joshua/rc-1.5b2
diff='diff -up'

for f in `cat FromRC`; do
  $diff $rcdist/$f ../$f
done
