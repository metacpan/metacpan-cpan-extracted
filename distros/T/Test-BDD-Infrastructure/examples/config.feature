Feature: test configuration files
Configuration values could be retrieved from different sources.
Read L<Test::BDD::Infrastructure::Config> for details.

In this example the following configuration backends are configured:

 - $c is the yaml config file in step_files/config.yaml
 - $a is the augeas backend
 - $f is the facter backend

See examples/00use_steps.pl on how they are loaded.

  Scenario: Resolver must point local resolver
    Then the value $a:/files/etc/resolv.conf/nameserver must be the string 127.0.0.1

  Scenario: The sshd configuration must be hardened
    Then the value $a:/files/etc/ssh/sshd_config/Protocol must be the string 2
    Then the value $a:/files/etc/ssh/sshd_config/UsePrivilegeSeparation must be like yes
    Then the value $a:/files/etc/ssh/sshd_config/PermitRootLogin must be like no
    Then the value $a:/files/etc/ssh/sshd_config/PermitEmptyPasswords must be like no

  Scenario: Should be running on a cool environment
    Then the value $f:kernel must be like Linux
    Then the value $f:lsbdistid must be like Debian
