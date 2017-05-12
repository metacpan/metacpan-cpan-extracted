Feature: swap space
Since the application is very hungry there must be a lot of swap available.

  Scenario: Swap space must be present
    Given swap is configured
    Then there must be at least 1 swap space configured
    And the swap size must be at least 1 gigabyte
    And the swap usage must be less than 50 percent

