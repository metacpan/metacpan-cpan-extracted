#!/bin/sh

# bash strict (see http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -euo pipefail
IFS=$'\n\t'

if [ "a" == "a" ]; then

  cd `mktemp -d`
  wget http://fishshell.com/files/2.2.0/fish-2.2.0.tar.gz
  tar xf fish-2.2.0.tar.gz
  cd fish-2.2.0
  ./configure --prefix=$HOME/travislocal
  make
  make install

fi
