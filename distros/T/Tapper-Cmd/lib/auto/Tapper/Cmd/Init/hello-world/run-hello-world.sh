#! /bin/bash

set -x

# ===== Hello World =====

# Initialize Tapper in $HOME/.tapper/
tapper init --default

# Start reports framework
start-tapper-daemon () {
    DAEMON=$1
    if ps auxwww | grep -v grep | grep $DAEMON ; then
        kill $(ps auxwww | grep -v grep | grep $DAEMON | awk '{print $2}')
    fi
    $DAEMON > /tmp/$DAEMON-helloworld.log    2>&1 &
}

start-tapper-daemon tapper_reports_web_server.pl
start-tapper-daemon tapper-reports-receiver
start-tapper-daemon tapper-reports-api

# Prepare test environment
source $HOME/.tapper/hello-world/00-set-environment/local-tapper-env.inc
cd $HOME/.tapper/hello-world/01-executing-tests/

# Execute tests
t/basic/example-01-basic.t
for t in $(find t/ -name "*.t") ; do $t ; done
for i in $(seq 1 5) ; do t/basic/example-03-benchmarks.t ; done

# Query API
cd $HOME/.tapper/hello-world/02-query-api/
cat hello.tt | netcat localhost 7358
cat benchmarks.tt | netcat localhost 7358
cat benchmarks-gnuplot.tt | netcat localhost 7358 | gnuplot
echo "eog $HOME/.tapper/hello-world/02-query-api/example-03-benchmarks.png"


# ===== Unobtrusive Automation =====

# Start automation
start-tapper-daemon tapper-mcp
start-tapper-daemon tapper-mcp-messagereceiver

# Create queues
tapper queue-new --name x86 --priority=100 --active
tapper queue-new --name arm --priority=100 --active

# Create hosts
tapper host-new --active --queue x86 --name einstein 2> /dev/null
tapper host-new --active --queue x86 --name hawking  2> /dev/null
tapper host-new --active --queue x86 --name newton   2> /dev/null
tapper host-new --active --queue arm --name ali      2> /dev/null
tapper host-new --active --queue arm --name hug      2> /dev/null
tapper host-new --active --queue arm --name dekkers  2> /dev/null
tapper host-list -v

# Enqueue tests
tapper testplan-new --file ~/.tapper/testplans/topic/helloworld/example01
tapper testplan-new --file ~/.tapper/testplans/topic/helloworld/example02

tapper testrun-list --schedule --verbose
