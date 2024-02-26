#!/bin/bash

set -eu

# Find non-global and non-ulib classes
find lib/RDF/Cowl/Lib/Gen/Class \
	-type f -name '*.pm' \
	\( \! -name '__GLOBAL__.pm' \) \
	\( -regextype posix-extended \! -regex '.*/U[A-Z][^/]*$' \) \
	-printf "%f\n" \
	| parallel '
		set -euo pipefail;
		CLASS_NAME={.};
		OUTPUT_PM="lib/RDF/Cowl/${CLASS_NAME}.pm"
		if [ ! -f $OUTPUT_PM ]; then
			TMP_DATA=$(mktemp --suffix=.json );
			jq -n --arg CLASS_NAME $CLASS_NAME '\''{ class_suffix: $CLASS_NAME }'\'' > $TMP_DATA
			tt-render --path=maint/tt --data=$TMP_DATA toplevel-class.pm.tt > $OUTPUT_PM
			rm $TMP_DATA
		else
			echo "Skipping $CLASS_NAME: already exists at $OUTPUT_PM" >&2;
		fi
	'
