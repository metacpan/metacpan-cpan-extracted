Feature: Updating attributes of entries within the directory
 As a directory consumer
 I want to ensure that I can adjust attributes on entries within the directory
 In order to extend or update entries with new or updated information

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can add a new attribute to an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   And I've added a new attribute to the new entry
   Then the new entry result is LDAP_SUCCESS
   And the new attribute result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can modify an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   And I've added a new attribute to the new entry
   And I've modified the new attribute on the new entry
   Then the new entry result is LDAP_SUCCESS
   And the new attribute result is LDAP_SUCCESS
   And the modified attribute result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can remove an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've added a new entry to the directory
   And I've added a new attribute to the new entry
   And I've removed the new attribute from the new entry
   Then the new entry result is LDAP_SUCCESS
   And the new attribute result is LDAP_SUCCESS
   And the removed attribute result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can asynchronously add a new attribute to an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   And I've asynchronously added a new attribute to the new entry
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And after waiting for all results, the new attribute result message type is LDAP_RES_MODIFY
   And the new attribute result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can asynchronously modify an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   And I've asynchronously added a new attribute to the new entry
   And I've asynchronously modified the new attribute on the new entry
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And after waiting for all results, the new attribute result message type is LDAP_RES_MODIFY
   And the new attribute result is LDAP_SUCCESS
   And after waiting for all results, the modified attribute result message type is LDAP_RES_MODIFY
   And the modified attribute result is LDAP_SUCCESS
   And the test container has been deleted

 Scenario: Can asynchronously remove an attribute on an entry within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've asynchronously bound with default authentication to the directory
   And a test container has been created
   And I've asynchronously added a new entry to the directory
   And I've asynchronously added a new attribute to the new entry
   And I've asynchronously removed the new attribute from the new entry
   Then after waiting for all results, the new entry result message type is LDAP_RES_ADD
   And the new entry result is LDAP_SUCCESS
   And after waiting for all results, the new attribute result message type is LDAP_RES_MODIFY
   And the new attribute result is LDAP_SUCCESS
   And after waiting for all results, the removed attribute result message type is LDAP_RES_MODIFY
   And the removed attribute result is LDAP_SUCCESS
   And the test container has been deleted
