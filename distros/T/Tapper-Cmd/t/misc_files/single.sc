scenario_type: multitest
description: 
  requested_hosts_all:
  - einstein
  queue: KVM
  topic: GarKeins
  preconditions:
    - precondition_type: testprogram
      program: /home/user/bin/start_client.sh
      parameters:
      - --first
      - --second
      timeout: 2000
    - precondition_type: hint
      local: 1
      skip_install: 1
