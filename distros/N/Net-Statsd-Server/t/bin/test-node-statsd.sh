#!/bin/sh
#
# Run Net::Statsd::Server integration tests
# against Etsy nodejs statsd. Quite neat.
#

# Where is your node executable?
NODE='/usr/bin/node'

# Where is Etsy's statsd source code?
ETSY_STATSD_SRC='../etsy-statsd/stats.js'

if [ ! -e './t' ]; then
    echo "Please run this script from the distribution root folder"
    exit 1
fi

TEST_CASES="$*"
TEST_CASES="${TEST_CASES:-t/integration-tests/*.t}"

export STATSD_BINARY="${NODE} ${ETSY_STATSD_SRC}"
export STATSD_CONFIG="${STATSD_CONFIG:-t/config/testConfig.js}"

prove -Ilib -mv $TEST_CASES
