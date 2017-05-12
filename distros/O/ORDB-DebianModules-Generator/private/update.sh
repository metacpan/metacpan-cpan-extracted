#!/bin/bash

if [ -f ~/.bash_custom_settings ]; then
    source ~/.bash_custom_settings
fi

set -e

cd `dirname $0`/..
perl -I ../Debian-ModuleList/lib/ -I lib ./bin/generate-debian-modules-database.pl output.db
if [ -f output.db.gz ]; then
    rm -f output.db.gz
fi
gzip output.db
scp output.db.gz alioth.debian.org:/var/lib/gforge/chroot/home/groups/pkg-perl/htdocs/db/DebianModules.db.gz
rm output.db.gz
