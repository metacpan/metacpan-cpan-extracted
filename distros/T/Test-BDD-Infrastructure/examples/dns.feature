Feature: DNS name resolution
DNS resolution is neccessary for the operation for the operation
of a mail server.

  Scenario: Internet sites must be resolvable
    Given the DNS resolver of the system is used
    When a DNS query for <domain> is sent
    Then the DNS answer must contain at least 1 record
    Examples:
    | domain |
    | www.heise.de |
    | www.google.de |
    | www.slashdot.org |
    | www.postfix.org |

  Scenario: Resolver must be DNSSEC aware
    Given the DNS resolver of the system is used
    And the DNS resolver dnssec flag is enabled
    When a DNS query for <domain> is sent
    Then the DNS answer must contain at least 1 record
    And the DNS header ad flag must be set
    Examples:
    | domain |
    | dane.sys4.de |

  Scenario: Most important DANE enabled mail providers must be resolvable
    Given the DNS resolver of the system is used
    And the DNS resolver dnssec flag is enabled
    When a DNS query for <domain> of type MX is sent
    Then the DNS header ad flag must be set
    And the DNS answer must contain a RR <domain>
    And the the DNS record exchange must be <mx>
    Examples:
    | domain | mx |
    | markusbenning.de | affenschaukel.bofh-noc.de |
    | sys4.de | mail.sys4.de |
