Feature: execute script and check output

  Scenario: /bin/true must work as expected
    Given the command is /bin/true
    And the commands timeout is set to 5 seconds
    When the command is executed
    Then the commands return value must be 0
    And the commands output must be empty
    And the commands error output must be empty

