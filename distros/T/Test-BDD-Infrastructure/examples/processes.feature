Feature: some processes must be running

  Scenario: mtpolicyd must be running
    Given a parent process like ^/usr/bin/mtpolicyd is running
    Then the uid of the process must be 116
    Then the gid of the process must be 119
    Then the priority of the process must be 20
    Then the RSS size of the process must be smaller than 67108864 byte
    When there are at least 3 child processes
    Then the uid of the process must be 116
    Then the gid of the process must be 119
    Then the priority of the process must be 20
    Then the RSS size of the process must be smaller than 64 MB

  Scenario: the postfix server must be running
    Given a parent process like /usr/lib/postfix/master is running
    Then the uid of the process must be root
    Then the gid of the process must be root
    Then the priority of the process must be 20
    Then the RSS size of the process must be smaller than 10 megabyte
    When there are at least 1 child processes like ^qmgr
    Then the uid of the child process must be postfix
    Then the gid of the child process must be postfix
    When there are at least 1 child processes like ^tlsmgr
    Then the uid of the process must be 106
    Then the gid of the process must be 109
    When there are at least 1 child processes like ^pickup
    Then the uid of the process must be 106
    Then the gid of the process must be 109
    When there are at least 1 child processes like ^smtpd
    Then the uid of the process must be 106
    Then the gid of the process must be 109
