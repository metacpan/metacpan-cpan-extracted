Feature: test files

  Scenario: test some files
    Given the file /etc/hosts exists
    Then the file must be non-zero size
    And the file type must be plain file
    And the file mode must be 0644
    And the file must be owned by user root
    And the file must be owned by group root
    And the file size must be at least 200 byte
    And the file mtime must be newer than 20 years
    And the file mtime must be older than 30 seconds
    And the file must contain at least 10 lines

  Scenario: test a directory
    Given the directory /etc exists
    Then the file type must be directory
    And the directory must contain at least 100 files
