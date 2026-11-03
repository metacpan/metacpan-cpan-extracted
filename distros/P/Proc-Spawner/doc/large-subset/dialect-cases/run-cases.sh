#!/bin/bash
# Run every example of cases.txt (ID TAB command) in dash and in bash --posix, each in a fresh empty directory.
# Usage: bash run-cases.sh cases.txt SCRATCHDIR > results.txt   (no files are deleted; SCRATCHDIR keeps the directories)
cases=$1; s=$2; mkdir -p "$s"
while IFS=$'\t' read -r id c; do
  d=$(cd "$(mktemp -d -p "$s")" && timeout 5 dash -c "$c" 2>&1 </dev/null; echo "<$?>")
  b=$(cd "$(mktemp -d -p "$s")" && timeout 5 bash --posix -c "$c" 2>&1 </dev/null; echo "<$?>")
  printf '%s\t%s\tDASH: %s\tBASH: %s\n' "$id" "$c" "$(echo "$d" | tr '\n' '|')" "$(echo "$b" | tr '\n' '|')"
done < "$cases"
