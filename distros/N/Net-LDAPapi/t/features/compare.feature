Feature: Comparing values to values of attributes of entries within the directory
 As a directory consumer
 I want to ensure that I can test the value of an attribute on an entry within the directory
 In order to perform simple comparisons

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can compare an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   And I've compared to an attribute on the new entry
   Then the new entry result is LDAP_SUCCESS
   And the new entry comparison result is LDAP_COMPARE_TRUE
   And the test container has been deleted

 Scenario: Can asynchronously compare an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   And I've asynchronously compared to an attribute on the new entry
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And after waiting for all results, the new entry comparison result message type is LDAP_RES_COMPARE
   And the new entry comparison result is LDAP_COMPARE_TRUE
   And the test container has been deleted
