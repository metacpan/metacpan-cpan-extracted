scenario_type: interdep
scenario_name: client-server
scenario_options:
  no_sync: 1
description: 
- requested_hosts_all:
  - einstein
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
- requested_hosts_all:
  - bohr
  preconditions:
    - precondition_type: testprogram
      program: /home/user/bin/start_server.sh
      parameters:
      - first
      - second
      timeout: 2000
    - precondition_type: hint
      local: 1
      skip_install: 1
