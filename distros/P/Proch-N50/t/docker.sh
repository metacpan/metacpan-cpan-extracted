#!/bin/bash
set -euxo pipefail
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil test --release "$@"
