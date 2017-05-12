Feature: Control of options used to configure the LDAP library
 As a directory consumer
 I want to ensure that I can control the options that are used to configure the LDAP client library
 In order to alter behaviour according to my needs

 Background:
   Given a usable Net::LDAPapi class

 Scenario: Can set and read back options
   Given a Net::LDAPapi object that has been connected to the LDAP server
   When I've set option LDAP_OPT_SIZELIMIT with value 200
   Then option LDAP_OPT_SIZELIMIT has value 200
