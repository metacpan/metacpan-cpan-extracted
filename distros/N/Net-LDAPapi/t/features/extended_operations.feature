Feature: Executing extended operations against the directory
 As a directory consumer
 I want to ensure that I can execute extended operations against the directory
 In order to use arbitrary LDAPv3 extensions

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can match identities retrieved with native whoami and using extended operations with anonymous authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with anonymous authentication to the directory
   And I've queried the directory for my identity
   And I've issued a whoami extended operation to the directory
   Then the identity result is LDAP_SUCCESS
   And the whoami extended operation result is LDAP_SUCCESS
   And the identity matches
   And the whoami extended operation matches

 Scenario: Can match identities retrieved with native whoami and using extended operations with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with simple authentication to the directory
   And I've queried the directory for my identity
   And I've issued a whoami extended operation to the directory
   Then the identity result is LDAP_SUCCESS
   And the whoami extended operation result is LDAP_SUCCESS
   And the identity matches
   And the whoami extended operation matches

 Scenario: Can asynchronously match identities retrieved with native whoami and using extended operations with anonymous authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with anonymous authentication to the directory
   And I've asynchronously queried the directory for my identity
   And I've asynchronously issued a whoami extended operation to the directory
   Then after waiting for all results, the identity result message type is LDAP_RES_EXTENDED
   And the identity result is LDAP_SUCCESS
   And after waiting for all results, the whoami extended operation result message type is LDAP_RES_EXTENDED
   And the whoami extended operation result is LDAP_SUCCESS
   And the identity matches
   And the whoami extended operation matches

 Scenario: Can asynchronously match identities retrieved with native whoami and using extended operations with simple authentication
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with simple authentication to the directory
   And I've asynchronously queried the directory for my identity
   And I've asynchronously issued a whoami extended operation to the directory
   Then after waiting for all results, the identity result message type is LDAP_RES_EXTENDED
   And the identity result is LDAP_SUCCESS
   And after waiting for all results, the whoami extended operation result message type is LDAP_RES_EXTENDED
   And the whoami extended operation result is LDAP_SUCCESS
   And the identity matches
   And the whoami extended operation matches
