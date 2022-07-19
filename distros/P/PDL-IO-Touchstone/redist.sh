#!/bin/sh

set -e

./rebuild-manifest.sh
./repod.sh

git diff
if [ -n "$(git status -s)" ]; then
	echo === GIT is dirty ===
	git status -s
	exit 1
fi

perl Makefile.PL && make && make test && make distcheck && make dist
