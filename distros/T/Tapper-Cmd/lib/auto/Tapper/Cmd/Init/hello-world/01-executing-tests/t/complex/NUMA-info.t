#! /bin/bash

. ./tapper-autoreport --import-utils

require_vendor_amd
require_kernel_config CONFIG_NUMA

# Expected values for AMD NB device functions should be the
# corresponding NUMA node id, all other device functions should
# be on NUMA node 0.
# It is explicitely wrong to contain -1.
append_tapdata "numainfo:"
for device in /sys/devices/pci0000\:00/*/numa_node; do
    NODEID=$(cat $device);
    echo $NODEID | grep -q -- '-'
    negate_ok $? "node info $device"
    append_tapdata "- device: '$device'"
    append_tapdata "  nodeid: '$NODEID'"
done

done_testing
