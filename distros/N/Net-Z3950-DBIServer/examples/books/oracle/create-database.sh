#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 <username> <password>" >&2
	exit 1
fi

make insert.sql &&
sqlplus -S "$1/$2" < create.sql &&
sqlplus -S "$1/$2" < insert.sql
