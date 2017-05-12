#! /bin/bash

stats=$(benchmarkanything-storage stats -o flat)
for var in count_datapoints count_metrics count_keys count_datapointkeys ; do
    declare ${var}=$(echo $stats | perl -ne "if (/$var=(\d+)/) { print \$1 }")
done

if [[ -z $TAPPER_TESTRUN ]] ; then
    export TAPPER_REPORTGROUP_ARBITRARY="selftest-$(date --iso-8601=date)"
fi

echo "1..2"
echo "# Test-suite-name: tapper-selftest"
echo "# Test-section: tapper-selftest"
echo "# Test-machine-name: $(hostname)"
if [[ -n $TAPPER_TESTRUN ]] ; then
    echo "# Test-reportgroup-testrun: $TAPPER_TESTRUN"
elif [[ -n $TAPPER_REPORTGROUP_ARBITRARY ]] ; then
    echo "# Test-reportgroup-arbitrary: $TAPPER_REPORTGROUP_ARBITRARY"
fi
echo "ok - dummy"
echo "ok - metrics"
echo "  ---"
echo "  BenchmarkAnythingData:"
echo "    - NAME:  tapper.selftest.bechmarks.count.datapoints"
echo "      VALUE: $count_datapoints"
echo "    - NAME:  tapper.selftest.bechmarks.count.metrics"
echo "      VALUE: $count_metrics"
echo "    - NAME:  tapper.selftest.bechmarks.count.keys"
echo "      VALUE: $count_keys"
echo "    - NAME:  tapper.selftest.bechmarks.count.datapointkeys"
echo "      VALUE: $count_datapointkeys"
echo "  ..."
