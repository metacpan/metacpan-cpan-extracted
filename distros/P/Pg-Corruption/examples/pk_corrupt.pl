# no output means that all is well (no corruption in table)
$ pk_corrupt.pl -U postgres -d lessons fk.person3

# same as above with more verbosely
$ pk_corrupt.pl -U postgres -d lessons fk.person3 -v
ok -- fk.person3 

# table did not exit, that is why it could not find pk
$ pk_corrupt.pl -U postgres -d lessons fk.person33  
Exiting... no pk found in "schema.person33"

# we can't access at table without permission
$ pk_corrupt.pl -d lessons fk.person3
ERROR:  permission denied for relation person3

# so we switch to another use and all goes well
$ pk_corrupt.pl -d lessons fk.person3 -U postgres
$
