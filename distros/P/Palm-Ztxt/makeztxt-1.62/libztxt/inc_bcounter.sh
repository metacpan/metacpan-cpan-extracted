#!/bin/sh

cnt=`cat buildcounter`
cnt=$(($cnt+1))
echo $cnt > buildcounter
