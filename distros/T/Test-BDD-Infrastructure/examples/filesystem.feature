Feature: the filesystem must provide space for storing the mail queue

  Scenario: There must be enought space for the mail queue
    Given a filesystem is mounted on /var/spool/postfix
    Then the filesystems type must be rootfs
    And the filesystems free space must be more than 200 megabyte
    And the filesystems usage must be less than 90 percent
