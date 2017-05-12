Feature: Listening for changes within the directory with syncrepl
 As a OpenLDAP directory consumer
 I want to ensure that I can be notified of changes to entries within the directory
 In order to act quickly on changes

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can listen for changes within the directory
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've bound with default authentication to the directory
   And a test container has been created
   And I've started listening for changes within the directory
   And I've added a new entry to the directory
   And I've added a new container to the directory  
   And I've deleted the new entry from the directory
   Then the new entry result is LDAP_SUCCESS
   And the new container result is LDAP_SUCCESS
   And the delete entry result is LDAP_SUCCESS
   And the changes were successfully notified
   And the test container has been deleted
