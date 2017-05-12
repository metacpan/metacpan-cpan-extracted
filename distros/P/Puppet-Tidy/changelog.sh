#!/bin/sh

[ ! -z $1 ] && tag=$1 || exit 1
tagref=$(git show-ref -s $tag)

IFS="%%"

echo "__VERSION__: $(date +%a\ %b\ %e\ %Y)\n========"

for c in $(git log --oneline ${tagref}..HEAD); do
	printf "  - %s" $c
done

echo
