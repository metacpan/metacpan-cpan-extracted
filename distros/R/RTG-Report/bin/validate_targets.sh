#!/bin/sh

sort targets.cfg > tmp/foo
sort /usr/local/etc/rtg/targets.cfg > tmp/bar
diff -bw tmp/foo tmp/bar
unlink tmp/foo 
unlink tmp/bar
