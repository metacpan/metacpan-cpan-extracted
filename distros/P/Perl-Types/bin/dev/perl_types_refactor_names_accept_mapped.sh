#!/usr/bin/env bash
#
# perl_types_refactor_names_accept_mapped.sh
#
# Accept mapped files by replacing originals with their -MAPPED counterparts.

set -euo pipefail

# For each mapped file, strip the '-MAPPED' suffix and overwrite the original.
find . -type f -name '*-MAPPED.*' | while IFS= read -r mapped; do
    dir=$(dirname "$mapped")
    file=$(basename "$mapped")
    # Remove '-MAPPED' from the filename to get the original
    orig="${file/-MAPPED/}"
    echo "Accepting mapped file: $mapped -> $dir/$orig"
    mv -v "$mapped" "$dir/$orig"
done