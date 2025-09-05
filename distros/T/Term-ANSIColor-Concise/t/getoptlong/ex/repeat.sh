#!/usr/bin/env bash

set -eu

declare -A OPTS=(
    [ count     | c :=i # repeat count              ]=1
    [ sleep     | i @=f # interval time             ]=
    [ paragraph | p ?   # print newline after cycle ]=
    [ trace     | x !   # trace execution           ]=
    [ debug     | d     # debug level               ]=0
    [ message   | m %=(^(BEGIN|END)=) # print message at BEGIN|END ]=
)
trace() { [[ $2 ]] && set -x || set +x ; }

. "$(dirname $0)"/../getoptlong.sh OPTS "$@"

column=$(command -v column) || column=cat
(( debug >= 3 )) && dumpopt=(--all) filter=$column
(( debug >= 2 )) && getoptlong dump ${dumpopt[@]} | ${filter:-cat} >&2

[[ ${1:-} =~ ^[0-9]+$ ]] && count=$1 && shift

message() { [[ -v message[$1] ]] && echo "${message[$1]}" || : ; }

message BEGIN
for (( i = 0; $# > 0 && i < count ; i++ )) ; do
    (( debug > 0 )) && echo "# [ ${@@Q} ]" >&2
    "$@"
    [[ -v paragraph ]] && echo "$paragraph"
    if (( ${#sleep[@]} > 0 )) ; then
	time="${sleep[$(( i % ${#sleep[@]} ))]}"
	(( debug > 0 )) && echo "# sleep $time" >&2
	sleep $time
    fi
done
message END
