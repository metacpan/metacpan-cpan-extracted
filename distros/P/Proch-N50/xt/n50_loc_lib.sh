#!/bin/bash

# This script copies bin/n50.pl - the main script using Proch::N50,
# in ./xt/ but using the local copy of Proch::50 instead of the system installed one

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
SOURCE="$SCRIPTDIR/../bin/n50"
DEST="$SCRIPTDIR/n50.pl"

if [ ! -e "$SOURCE" ]; then
	echo "Source script not found: $SOURCE"
	exit 1
else
	set -euo pipefail;
	if [[ -e "$DEST" ]]; then
		rm "$DEST";
	fi

	echo "# Copying script $SOURCE to $DEST: "
	sed 's|#~loclib~|use lib "$Bin/../lib";|' "$SOURCE" > "$DEST"
	echo "# OK"
	echo "# Testing script:";
	DATA=$(perl "$SCRIPTDIR/n50.pl" "$SCRIPTDIR/../data/"*.fa --format tsv)
	if [[ $? -gt 0 ]]; then
		exit 3;
	else
		echo "OK"
		echo $DATA;
	fi
fi

## Update the README.md file
VERSION=$(grep VERSION $SCRIPTDIR/../lib/Proch/N50.pm | perl -ne 'if ($_=~/(\d+\.\d+)/) { print "$1" }')
sed "s/{version}/$VERSION/g" README.template > README.md
