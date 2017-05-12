Feature: test http servers

  Scenario: A URL must be reachable
    Given the http URL $url
    Given the http user agent is Test-BDD-Infrastructure/1.000
    Given the http ssl option verify_hostname is 1
    Given the http proxy for https is http://localhost:8888
    When the http request is sent
    Then the http response must be a redirect
    And the http response status code must be 302
    And the http response status message must be like ^Found
    And the http response header Location must be like ^https://markusbenning.de/blog/
    And the http response header Content-Type must be like text/html
    And the http response content must be like The document has moved
    And the http response content size must be at least 200 byte
