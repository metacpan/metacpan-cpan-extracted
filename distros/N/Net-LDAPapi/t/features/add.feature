Feature: Adding entries to the directory
 As a directory consumer
 I want to ensure that I can add entries to the directory
 In order to store information

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can add a new entry to the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   Then the new entry result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can asynchronously add a new entry to the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And the test container has been deleted
