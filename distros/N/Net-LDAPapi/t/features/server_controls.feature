Feature: Using server controls to control results
 As a directory consumer
 I want to ensure that I can use server controls when querying the directory
 In order to be able to utilise the extended features of my directory

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can use the Server Side Sort control and Virtual List View Control
   Given a Net::LDAPapi object that has been connected to the LDAP server
   And the server side sort control definition
   And the virtual list view control definition
   When I've bound with default authentication to the directory
   And I've created a server side sort control
   And I've created a virtual list view control
   And I've searched for records with scope LDAP_SCOPE_SUBTREE, with server controls server side sort and virtual list view
   Then the search result is LDAP_SUCCESS
   And the search count matches
   And using next_entry for each entry returned the dn and all attributes using next_attribute are valid
   And the server side sort control was successfully used
   And the virtual list view control was successfully used
