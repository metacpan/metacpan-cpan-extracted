Feature: socket based checks

  Scenario: A connection to non-existent port must fail
    Given a tcp connection to localhost on port 54321 is made
    Then the connection must fail with connection refused

  Scenario: A successfull connection
    Given a tcp connection to www.perl.org on port 80 is made
    Then the connection must be successfully enstablished
    When the connection sends the line GET / HTTP/1.0
    And the connection sends the line Host: www.perl.org
    And the connection sends an empty line
    Then the connection must recieve an line like HTTP/1.1 301 Moved Permanently

  Scenario: check openssh server
    Given a tcp connection to localhost on port 22 is made
    Then the connection must be successfully enstablished
    And the connection must recieve an line like ^SSH-2.0

