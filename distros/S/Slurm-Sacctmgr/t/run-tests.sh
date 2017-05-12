#!/bin/sh

if [ "x$1" = 'x-a' ]; then
	RELEASE_TESTING=1
	export RELEASE_TESTING
fi

#To get 050_pod.t to run properly, need to be in dir above t
cd ..

perl -I lib -MTest::Harness -e "runtests(<t/*.t>)"
