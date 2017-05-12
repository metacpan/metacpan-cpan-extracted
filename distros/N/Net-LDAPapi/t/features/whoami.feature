Feature: Querying the directory for my identity
 As a directory consumer
 I want to ensure that I can retrieve my identity
 In order to determine my DN when using a non-simple authentication

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can query identity with anonymous authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with anonymous authentication to the directory
   And I've queried the directory for my identity
   Then the bind result is LDAP_SUCCESS
   And the identity result is LDAP_SUCCESS
   And the identity matches

 Scenario: Can query identity with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with simple authentication to the directory
   And I've queried the directory for my identity
   Then the bind result is LDAP_SUCCESS
   And the identity result is LDAP_SUCCESS
   And the identity matches

 Scenario: Can query identity with sasl authentication
   Given a Net::LDAPapi object that has been connected to the ldapi LDAP server
   When I've bound with sasl authentication to the directory
   And I've queried the directory for my identity
   Then the bind result is LDAP_SUCCESS
   And the identity result is LDAP_SUCCESS
   And the identity matches

 Scenario: Can asynchronously query identity with anonymous authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with anonymous authentication to the directory
   And I've asynchronously queried the directory for my identity
   Then the bind result message type is LDAP_RES_BIND
   And the bind result is LDAP_SUCCESS
   And after waiting for all results, the identity result message type is LDAP_RES_EXTENDED
   And the identity result is LDAP_SUCCESS
   And the identity matches

 Scenario: Can asynchronously query identity with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with simple authentication to the directory
   And I've asynchronously queried the directory for my identity
   Then the bind result message type is LDAP_RES_BIND
   And the bind result is LDAP_SUCCESS
   And after waiting for all results, the identity result message type is LDAP_RES_EXTENDED
   And the identity result is LDAP_SUCCESS
   And the identity matches

# Scenario: Can asynchronously query identity with sasl authentication
#   Given a Net::LDAPapi object that has been connected to the ldapi LDAP server
#   When I've asynchronously bound with sasl authentication to the directory
#   And I've asynchronously queried the directory for my identity
#   Then the bind result message type is LDAP_RES_BIND
#   And the bind result is LDAP_SUCCESS
#   And after waiting for all results, the identity result message type is LDAP_RES_EXTENDED
#   And the identity result is LDAP_SUCCESS
#   And the identity matches
