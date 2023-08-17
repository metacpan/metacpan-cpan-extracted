#!/bin/sh

if ! [ -e MANIFEST ]; then 
	echo 'Existing MANIFEST file not found.  Are you in the wrong directory?'
	exit 1
fi

git ls-tree -r master --name-only |grep -v '\.gitignore' | sort | tee MANIFEST

