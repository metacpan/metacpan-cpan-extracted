use Test::More tests => 3;

# use the module
use_ok('MyLibrary::DB');

# create a handle
my $dbh = MyLibrary::DB->dbh();
like($dbh, qr/DBI/, 'dbh() connection successful');

# get the next sequence
my $id = MyLibrary::DB->nextID();
like ($id, qr/^\d+$/, 'nextID()'); 
