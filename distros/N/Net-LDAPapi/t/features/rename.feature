Feature: Renaming entries within the directory
 As a directory consumer
 I want to ensure that I can rename entries within the directory
 In order to reorganise information

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can rename an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   And I've added a new container to the directory
   And I've moved the new entry to the new container
   Then the new entry result is LDAP_SUCCESS
   And the new container result is LDAP_SUCCESS
   And the rename entry result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can asynchronously rename an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   And I've asynchronously added a new container to the directory
   And I've asynchronously moved the new entry to the new container
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And after waiting for all results, the new container result message type is LDAP_RES_ADD
   And the new container result is LDAP_SUCCESS
   And after waiting for all results, the rename entry result message type is LDAP_RES_MODDN
   And the rename entry result is LDAP_SUCCESS
   And the test container has been deleted
