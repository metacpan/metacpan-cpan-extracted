#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo "DIR=$DIR"
cd "$DIR/../../"
rm -rfv FASTX-*
if [[ -e "experimental" ]];
then
	mv experimental ../_build_fastx_reader_exp
fi
cd -
