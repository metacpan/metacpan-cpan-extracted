Feature: Binding to the directory
 As a directory consumer
 I want to ensure that I can bind properly to directories
 In order to establish my identity

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can bind anonymously
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with anonymous authentication to the directory
   Then the bind result is LDAP_SUCCESS

 Scenario: Can bind with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with simple authentication to the directory
   Then the bind result is LDAP_SUCCESS

 Scenario: Can bind with sasl authentication
   Given a Net::LDAPapi object that has been connected to the ldapi LDAP server
   When I've bound with sasl authentication to the directory
   Then the bind result is LDAP_SUCCESS

 Scenario: Can asynchronously bind anonymously
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with anonymous authentication to the directory
   Then the bind result message type is LDAP_RES_BIND
   And the bind result is LDAP_SUCCESS

 Scenario: Can asynchronously bind with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with simple authentication to the directory
   Then the bind result message type is LDAP_RES_BIND
   And the bind result is LDAP_SUCCESS

# Scenario: Can asynchronously bind with sasl authentication
#   Given a Net::LDAPapi object that has been connected to the ldapi LDAP server
#   When I've asynchronously bound with sasl authentication to the directory
#   Then the bind result message type is LDAP_RES_BIND
#   And the bind result is LDAP_SUCCESS
