#! /bin/bash

SIZE_MB=100
#SIZE_MB=4096
TIMEFILE="/tmp/cpb_time_$$.dat"
SYS_PATH="/sys/devices/system/cpu"
FORMAT="%U"

. ./tapper-autoreport --import-utils

# ==================== UTILS ====================

if [ -r $SYS_PATH/cpufreq/boost ] ; then
        SYS_CPB=$SYS_PATH/cpufreq/boost
        ok 0 "using acpi-cpufreq boost disable interface"
elif [ -r $SYS_PATH/cpu0/cpufreq/cpb ] ; then
        SYS_CPB=$SYS_PATH/cpu0/cpufreq/cpb
        ok 0 "using legacy cpb boost disable interface"
else
        autoreport_skip_all "no sysfs boost disable interface"
fi

enable_cpb() {
        OLDCPB=$(cat $SYS_CPB)
        echo 1 > $SYS_CPB
        #echo '# enable cpb to' $(cat $SYS_CPB) 1>&2
}

disable_cpb() {
        OLDCPB=$(cat $SYS_CPB)
        echo 0 > $SYS_CPB
        #echo '# disable cpb to' $(cat $SYS_CPB) 1>&2
}

restore_cpb() {
    echo $OLDCPB > $SYS_CPB
    #echo '# restore cpb to' $(cat $SYS_CPB) 1>&2
}

# it looks like: ctr=1000000;while [ $ctr - gt 0 ]; do let ctr-=1; done
# scales better with frequency, at it stays within usermode for longer periods
# counting from 1 million takes approx. 10 seconds at 3 GHz
# maybe we should replace md5sum with this algorithm

do_md5sum_zeroes() {
        /usr/bin/time -o $TIMEFILE --format "$FORMAT" sh -c "dd if=/dev/zero bs=1M count=$1 status=noxfer 2> /dev/null | md5sum - > /dev/null 2>&1"
        cat $TIMEFILE | sed -e "s/^0\.//" | tr -d .
}

# ==================== REQUIREMENTS ====================

require_root
require_crit_level 3 # toggle CPB
if ! has_cpufeature cpb &&  ! has_cpufeature ida ; then
        autoreport_skip_all "CPU does not support boosting"
else
        ok 0 "CPU does support boosting"
fi

# ==================== PREPARE ====================

# ==================== WARMUP RUN ====================

#echo '# warmup run...' 1>&2
TIME_WARMUP=$(do_md5sum_zeroes $SIZE_MB)
#echo '# warmup time:' $TIME_WARMUP 1>&2

# ==================== FIRST RUN ====================

enable_cpb

#echo '# measure time with cpb...' 1>&2
TIME_CPB=$(do_md5sum_zeroes $SIZE_MB)
#echo '# cpb time:' $TIME_CPB 1>&2

[ $TIME_CPB -gt 0 ]
ok $? "Boost run successful"

restore_cpb

# ==================== SECOND RUN ====================

disable_cpb

#echo '# measure time with cpb disabled...' 1>&2
TIME_NOCPB=$(do_md5sum_zeroes $SIZE_MB)
#echo '# no cpb time:' $TIME_NOCPB 1>&2

[ $TIME_NOCPB -gt 0 ]
ok $? "Non-boost run successful"

restore_cpb

# ==================== RATIO CPB vs. NOCPB ====================

if [ "$TIME_NOCPB" -gt 0 -a "$TIME_CPB" -gt 0 ] ; then
    TIME_RATIO=$((TIME_CPB*100/TIME_NOCPB))
else
    TIME_RATIO="~" # YAML undef
    SKIP="# SKIP ignored due to runtime of zero time"
fi

# ==================== FASTER? ====================

[ "$TIME_RATIO" -lt 95 ]
ok $? "CPB faster than no CPB $SKIP"

# ==================== TAP ====================

append_tapdata "timecpb: $TIME_CPB"
append_tapdata "timenocpb: $TIME_NOCPB"
append_tapdata "ratio: $TIME_RATIO"

# ==================== CLEANUP ====================

/bin/rm $TIMEFILE

# ==================== DONE ====================

# ==================== REPORT ====================

done_testing

# vim: set ts=4 sw=4 tw=0 ft=sh:
