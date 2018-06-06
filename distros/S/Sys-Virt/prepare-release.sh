#!/bin/sh

NAME=Sys-Virt

set -e

rm -rf blib _build Build $NAME-*.tar.gz

export TEST_MAINTAINER=1

perl Build.PL install_base=$HOME/builder

./Build
./Build test
./Build install
./Build dist

if [ -f /usr/bin/rpmbuild ]; then
  rpmbuild --nodeps -ta --clean $NAME-*.tar.gz
fi
