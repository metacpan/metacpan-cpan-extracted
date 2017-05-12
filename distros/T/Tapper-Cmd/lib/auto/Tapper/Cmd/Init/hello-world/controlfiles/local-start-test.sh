#! /bin/bash

# This script shows how to initialize any test of type 'local'.
#
# This here is NOT the actual test but the STARTER of your test.
# Write such a script for your personal use-case, e.g.
#
#  - start a remote test on a machine via ssh to $TAPPER_HOSTNAME and
#    take care of everything by yourself during the scope of that
#    test.
#
#  - execute autoreport-scripts locally
#
# This script here must output TAP for its own status reporting, feel
# free to print it TAP on your own or use Tapper-autoreport.

start_a_test () {
    _testrun=${1:-}
    _host=${2:-unknown}
    echo "# Starting testrun '$_testrun' on host '$_host'"
    return 0
}

main () {
        echo "1..2"
        NOT=""
        start_a_test "$TAPPER_TESTRUN" "$TAPPER_HOSTNAME" || NOT="not "
        echo "${NOT}ok - example: executed something on $TAPPER_HOSTNAME"
        echo "ok - something else for $TAPPER_TESTRUN"
}

main
