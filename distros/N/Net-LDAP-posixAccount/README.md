# Net-LDAP-posixAccount

Creates new Net::LDAP::Entry objects for a posixAccount entry

```
# Initiates the module with a base DN of 'ou=users,dc=foo'.
my $foo = Net::LDAP::posixAccount->new(baseDN=>'ou=user,dc=foo');

# create the user vvelox with a gid of 404 and a uid of 404
# see the POD for Net::LDAP::Entry for additional args supported
my $entry = $foo->create(name=>'vvelox', gid=>'404', uid=>'404');

# add it using $ldap, a previously created Net::LDAP object
$entry->update($ldap);
```
