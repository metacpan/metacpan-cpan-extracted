#!/bin/bash
echo "AFTER BUILD"
#set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR/../.."
if [[ -e "../_build_fastx_reader_exp" ]]; then
  mv ../_build_fastx_reader_exp experimental
fi
cd -
