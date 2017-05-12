#!/bin/sh
#
# Run Net::Statsd::Server integration tests
#

if [ ! -e './t' ]; then
    echo "Please run this script from the distribution root folder"
    exit 1
fi

TEST_CASES="$*"
TEST_CASES="${TEST_CASES:-t/integration-tests/*.t}"

prove -Ilib -mv $TEST_CASES
