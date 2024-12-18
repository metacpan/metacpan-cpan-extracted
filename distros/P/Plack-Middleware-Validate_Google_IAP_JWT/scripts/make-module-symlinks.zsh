#!/bin/zsh

emulate -L zsh

# This script depends on GNU ln and find.

setopt err_return

realScriptFn=$(readlink -f $0) || exit 1
projDir=$realScriptFn:h:h
libDir=$projDir/lib

#----------------------------------------

zparseopts -D -K n=o_dryrun

function usage {
    if ((ARGC)); then
        echo 1>&2 "$@"
    fi
    cat 1>&2 <<EOF
Usage: ${realScriptFn:t} DEST_LIBDIR

Creates symlinks and directories for perl modules
EOF
    exit 1
}

function x {
    print "#" ${(@q-)argv}
    if (($#o_dryrun)); then return; fi
    "$@"
}

((ARGC)) || usage

destDir=$1

[[ -d $destDir ]] || usage "Invalid destination directory! '$destDir'"

(cd $libDir

 find -type f -name '*.pm' -printf '%P\n'
) | while read fn; do
    dn=$destDir/$fn:h
    [[ -d $dn ]] || x mkdir -p $dn
    x ln -vnsfr $libDir/$fn $destDir/$fn
done

