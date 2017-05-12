package # hidden from cpan
    Monitoring::Generator::TestConfig::ShinkenInitScriptData;

use strict;
use warnings;

########################################

=over 4

=item get_init_script

    returns the init script source

    adapted from the nagios debian package

=back

=cut

sub get_init_script {
    my $self      = shift;
    my $prefix    = shift;
    my $binary    = shift;
    our $initsource;
    if(!defined $initsource) {
       while(my $line = <DATA>) { $initsource .= $line; }
    }

    my $binpath = $binary;
    $binpath =~ s/^(.*)\/.*$/$1/mx;

    my $initscript = $initsource;
    $initscript =~ s/__PREFIX__/$prefix/gmx;
    $initscript =~ s/__BIN__/$binpath/gmx;
    return($initscript);
}

1;

__DATA__
#!/bin/sh

### BEGIN INIT INFO
# Provides:          shinken
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: shinken
# Description:       shinken monitoring daemon
### END INIT INFO

NAME="shinken"
SCRIPTNAME=$0
AVAIL_MODULES="scheduler poller reactionner broker arbiter receiver"
BIN="__BIN__"
VAR="__PREFIX__/var"
ETC="__PREFIX__/etc"

usage() {
    echo "Usage: $SCRIPTNAME [ -d ] {start|stop|restart|status|check} [ <$AVAIL_MODULES> ]" >&2
    echo ""                                                                           >&2
    echo " -d  start module in debug mode, only useful with start|restart"            >&2
    echo ""                                                                           >&2
    exit 3
}

DEBUG=0
while getopts "d" flag; do
    case "$flag" in
        d)
            DEBUG=1
        ;;
    esac
done
shift `expr $OPTIND - 1`

CMD=$1
shift
SUBMODULES=$*

if [ -z "$SUBMODULES" ]; then
    SUBMODULES=$AVAIL_MODULES
else
    # verify given modules
    for mod1 in $SUBMODULES; do
        found=0
        for mod2 in $AVAIL_MODULES; do
            [ $mod1 = $mod2 ] && found=1;
        done
        [ $found = 0 ] && usage
    done
fi


# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

# Define LSB log_* functions.
[ -f /lib/lsb/init-functions ] && . /lib/lsb/init-functions

#
# return the pid for a submodule
#
getmodpid() {
    mod=$1
    pidfile="$VAR/${mod}d.pid"
    if [ $mod = 'arbiter' ]; then
        pidfile="$VAR/shinken.pid"
    fi
    if [ -s $pidfile ]; then
        cat $pidfile
    fi
}

#
# stop modules
#
do_stop() {
    ok=0
    fail=0
    for mod in $SUBMODULES; do
        pid=`getmodpid $mod`;
        printf "%-15s: " $mod
        if [ ! -z $pid ]; then
            maxkill=5
            running=$(ps -aefw | grep $pid | grep "shinken-" | wc -l)
            while [ $running -gt 0 -a $maxkill -gt 0 ]; do
                for cpid in $(ps -aefw | grep $pid | grep "shinken-" | awk '{print $2}' | sort -g -r); do
                    kill $cpid > /dev/null 2>&1
                done
                sleep 1
                maxkill=$(($maxkill - 1))
                running=$(ps -aefw | grep $pid | grep "shinken-" | wc -l)
            done
            if [ $running -gt 0 ]; then
                echo "failed"
            else
                echo "done"
            fi
        else
            echo "done"
        fi
    done
    return 0
}


#
# Display status
#
do_status() {
    MODULES=$1
    [ -z $MODULES ] && MODULES=$SUBMODULES;
    ok=0
    fail=0
    echo "status $NAME: ";
    for mod in $MODULES; do
        pid=`getmodpid $mod`;
        printf "%-15s: " $mod
        if [ ! -z $pid ]; then
            ps -p $pid >/dev/null 2>&1
            if [ $? = 0 ]; then
                echo "RUNNING (pid $pid)"
                ok=$((ok+1))
            else
                echo "NOT RUNNING"
                fail=$((fail+1))
            fi
        else
            echo "NOT RUNNING"
            fail=$((fail+1))
        fi
    done
    if [ $fail -gt 0 ]; then
        return 1
    fi
    return 0
}

#
# start our modules
#
do_start() {
    printf "starting $NAME";
    [ $DEBUG = 1 ] && printf " (DEBUG Mode)"
    echo ": "
    for mod in $SUBMODULES; do
        printf "%-15s: " $mod
        DEBUGCMD=""
        [ $DEBUG = 1 ] && DEBUGCMD="--debug $VAR/${mod}-debug.log"
        do_status $mod  > /dev/null 2>&1
        if [ $? = 0 ]; then
            pid=`getmodpid $mod`;
            echo "ALREADY RUNNING (pid $pid)"
        else
            if [ $mod != "arbiter" ]; then
                output=`cd $BIN && ./shinken-${mod} -d -c $ETC/${mod}d.cfg $DEBUGCMD 2>&1`
            else
                output=`cd $BIN && ./shinken-${mod} -d -c $ETC/../shinken.cfg -c $ETC/shinken-specific.cfg $DEBUGCMD 2>&1`
            fi
            if [ $? = 0 ]; then
                echo "OK"
            else
                output=`echo "$output" | tail -2` # only show last 2 lines of error output...
                echo "FAILED $output" 
            fi
        fi
    done
}

#
# do the config check
#
do_check() {
    cd $BIN && ./shinken-arbiter -v -c $ETC/../shinken.cfg -c $ETC/shinken-specific.cfg $DEBUGCMD 2>&1
    return $?
}

#
# check for our command
#
case "$CMD" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $NAME"
    do_start
    do_status > /dev/null 2>&1
    rc=$?
    case $rc in
        0) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
    esac
    exit $rc
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $NAME"
    do_stop
    do_status > /dev/null 2>&1
    case $? in
        0) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
    esac
    exit 0
    ;;
  restart)
    [ "$VERBOSE" != no ] && log_daemon_msg "Restarting $NAME"
    do_stop
    do_status > /dev/null 2>&1
    case "$?" in
      1)
        do_start
        do_status > /dev/null 2>&1
        case "$?" in
            0) log_end_msg 0 ;;
            *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
        ;;
    esac
    ;;
  status)
    do_status
    ;;
  check|checkconfig)
    do_check
    case "$?" in
        0) log_end_msg 0 ;;
        *) log_end_msg 1 ;; # Failed config check
    esac
    ;;
  *)
    usage;
    ;;
esac
