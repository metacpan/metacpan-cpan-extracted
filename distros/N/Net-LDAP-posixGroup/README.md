# Net-LDAP-posixGroup

Creates new Net::LDAP::Entry object for a posixGroup entry

```
use Net::LDAP::posixGroup;

my $foo = Net::LDAP::posixGroup->new(baseDN=>'ou=group,dc=foo');
    
#creates a new for the group newGroup with a GID of 404 and members of user1 and user2.
my $entry = $foo->create(
    name    => 'newGroup',
	gid     => 404,
	members => ['user1', 'user2']
	);

print $entry->ldif;
```
