#!/bin/bash
set -euxo pipefail
sleep 2
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil test --release "$@"
