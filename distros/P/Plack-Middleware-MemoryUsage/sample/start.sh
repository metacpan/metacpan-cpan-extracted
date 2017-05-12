#!/bin/sh

me=$(readlink -f $0)
basedir=${me%/*}

exec plackup -I${basedir}/../lib -I${basedir} -p 9999 -s Starlet --max-workers=1 t.psgi
