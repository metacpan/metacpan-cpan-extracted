#! /bin/bash

# ------------------------------------------------------------------
#
# This is an example script to be used by a "Tapper precondition
# producer" as described in
#
#   http://tapper-testing.org/docs/tapper-manual.pdf
#   pg. 45ff
#
# It should be used via "Tapper::Producer::ExternalProgram" and must
# generate its result as a precondition YAML text printed to STDOUT.
#
# Take care nothing else prints to STDOUT.
#
# ------------------------------------------------------------------

# --- prepare ---

prepare () {
    TARGETDIR=${TARGETDIR:-/tmp}
    TARGETNAME=${TARGETNAME:-FAKE-KERNEL-PACKAGE}

    # specific, or common testplan, or common testrun, or process ID
    TARGETID=${TARGETID:-${TAPPER_TESTPLAN:-${TAPPER_TESTRUN:-$$}}}
    GENERATED_FILE="$TARGETDIR/$TARGETNAME-$TARGETID.tgz"
}

build_kernel ()
{

    # build the fake kernel package

    tempdir=$(mktemp -d)
    CONTEXT=context.txt
    BUILER_TAP="$tempdir/$TARGETID.tap"

    # create builder report outside of STDOUT
    echo "1..3"                                               > $BUILER_TAP
    echo "# Test-suite-name: " $(basename $0)              >> $BUILER_TAP
    echo "# Test-machine-name: " $(hostname)               >> $BUILER_TAP   # alternative: use $TAPPER_HOSTNAME (the *target* hostname)
    if [ -n "$TAPPER_TESTRUN" ] ; then
        echo "# Test-reportgroup-testrun: $TAPPER_TESTRUN" >> $BUILER_TAP
    fi
    if [ ! -d "$tempdir" ] ; then echo -n "not "             >> $BUILER_TAP ; fi
    echo "ok - tempdir created"                              >> $BUILER_TAP

    cd $tempdir
    (
        echo "------------------------------------------------------------"
        echo ""
        echo "We were called with:"
        echo "  $0 " "${@}"
        echo ""
        echo "------------------------------------------------------------"
        echo ""
        echo "some env:"
        echo ""
        echo "CHOST: $CHOST"
        echo "CFLAGS: $CFLAGS"
        echo "CXXFLAGS: $CXXFLAGS"
        echo "TARGETDIR: $TARGETDIR"
        echo "TARGETID: $TARGETID"
        echo "TARGETNAME: $TARGETNAME"
        echo "TAPPER_TESTRUN: $TAPPER_TESTRUN"
        echo "TAPPER_TESTPLAN: $TAPPER_TESTPLAN"
        echo "TAPPER_HOSTNAME: $TAPPER_HOSTNAME"
        echo "TAPPER_SERVER: $TAPPER_SERVER_"
        echo "TAPPER_REPORT_SERVER: $TAPPER_REPORT_SERVER"
        echo "TAPPER_REPORT_PORT: $TAPPER_REPORT_PORT"
        echo "TAPPER_REPORT_API_PORT: $TAPPER_REPORT_API_PORT"
        echo ""
        echo "full env:"
        echo ""
        echo "------------------------------------------------------------"
        echo ""
        env|grep -v LESS_TERMCAP
    ) > $CONTEXT


    FAKEKERNEL="kernel-3.0-$TARGETID.tar.gz"
    echo "affe zomtec birne tiger fink und star" > $FAKEKERNEL

    echo "ok - fake kernel generated"           >> $BUILER_TAP
    echo "# generated kernel: $FAKEKERNEL"      >> $BUILER_TAP

    tar czf $GENERATED_FILE *

    echo "ok - package generated"               >> $BUILER_TAP
    echo "# generated package: $GENERATED_FILE" >> $BUILER_TAP

    send_builder_report

    rm -fr "$tempdir"
}

output_precondition ()
{
    echo "---
precondition_type: testprogram
program: $HOME/.tapper/hello-world/controlfiles/example_kernel_install.sh
parameters:
  - $GENERATED_FILE
capture: tap
---
precondition_type: testprogram
program: /bin/sleep
parameters:
  - 2
"
}

# stolen from tapper-autoreport.autoreport_start()
send_builder_report ()
{
    NETCAT=$(which netcat 2> /dev/null || which nc 2> /dev/null)
    # does it provide -q option
    if $NETCAT -h 2>&1 |grep -q -- '-q.*quit' ; then
        NETCAT="$NETCAT -q3"
    else
        NETCAT="$NETCAT -w3"
    fi

    if [ -n "$TAPPER_REPORT_SERVER" -a -n "$TAPPER_REPORT_PORT" ] ; then
        MYNETCAT="$NETCAT $TAPPER_REPORT_SERVER $TAPPER_REPORT_PORT"
        output=$(cat $BUILER_TAP | $MYNETCAT ) # capture STDOUT to not pollute our own
    fi
}

main ()
{
    prepare

    # avoid rebuilding the same
    if [ -e $GENERATED_FILE ] ; then
        # make it a YAML '#' comment line, just in case someone redirects us STDOUT
        echo "# File $GENERATED_FILE already exists - skip building." 1>&2
    else
        build_kernel
    fi

    output_precondition
}

main
