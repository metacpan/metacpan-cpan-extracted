[%- IF machines     == '' %][% machines       = 'athene,bullock' %][% END -%]
[%- AllMachines       = machines.split(',')       || [] -%]
###
###   Self documentation for test
###
scenario_type: interdep
description: 
- requested_hosts_all:
[% FOREACH machine = AllMachines -%]
  - [% machine %]
[% END -%]
  preconditions:
  - arch: linux64
    image: suse/suse_sles10_64b_smp_raw.tar.gz
    mount: /
    partition: testing
    precondition_type: image
  - precondition_type: testprogram
    file: /opt/tapper/bin/netperf_client
- requested_hosts_all:
[% FOREACH machine = AllMachines -%]
  - [% machine %]
[% END -%]
  preconditions:
  - arch: linux64
    image: suse/suse_sles10_64b_smp_raw.tar.gz
    mount: /
    partition: testing
    precondition_type: image
  - precondition_type: testprogram
    file: /opt/tapper/bin/netperf_server
