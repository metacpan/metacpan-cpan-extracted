.DELETE_ON_ERROR:
.ONESHELL:
SHELL := bash
.SHELLFLAGS := -euo pipefail -O extglob -c

BATS=bats

test:
	for t in *.bats ; do
	    if [[ $$t =~ _repeat.bats$$ ]] ; then
		for script in ../ex/repeat.sh ../ex/prefix.sh ../ex/dest.sh ; do
		    echo $(BATS) $$script
		    SCRIPT_UNDER_TEST=$$script bats $$t
		done
	    else
		bats $$t
	    fi
	done
