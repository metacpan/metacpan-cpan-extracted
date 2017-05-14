# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }

use blib      '../Object'   ; # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;
use blib      '../Acl' ;

use        Notes::Session;    # note: inherits from Notes::Object
use        Notes::Database;   # note: inherits from Notes::Object
use        Notes::Acl;        # note: inherits from Notes::Object

# use        Devel::Peek;

use        Notes::AclEntry;

   # Test 1 - checks wether (dyna)loading the (XS) module works
print "ok 1\n";
$loaded = 1;
END { print "not ok 1\n" unless $loaded; }

######################### End of black magic.



$s    = new Notes::Session;
$db   = $s-> get_database( 'perlcapi/test/acl/names.nsf' );
$db_1 = $s-> get_database( 'perlcapi/test/acl/api461re.nsf');



print "\n";
$a = $db->get_acl;
$e = $a->entries_by_name( q(-Default-) );
$e->set_status( 1060 ); # status code for "The name is not in the list"
print "\nACL Entry Inheritance Test:\n",$e->status_text,"\n",$e->status,"\n";



print "\n";
print "Single ACL Entry Objects for ", $db->expanded_path, "\n";
$e = $a->entries_by_name( q(-Default-) );
print "Returned object from a->entry_by_name is a: ", ref $e,   "\n";
print "It's the Notes::ACLEntry for:         ", $e->name, "\n";

$e = $a->entries( q(LocalDomainServers) );
print "Returned object from a->entries is a: ", ref $e,   "\n";
print "It's the Notes::ACLEntry for:         ", $e->name, "\n";

$e = $a->entries( q(OtherDomainServers) );
print "Returned object from a->entries is a: ", ref $e,         "\n";
print "It's the Notes::ACLEntry for:         ", $e->name, "\n";



print "\n";
print "All ACL Entry Objects for ", $db->expanded_path, "\n";
@entries = $a->all_entryobjects;

foreach my $e ( @entries ) {
   print ref $e,   "\n";
   print $e->name, "\n";
}



print "\n";
print "All ACL Entry Objects for ", $db_1->expanded_path, "\n";
$a_1     = $db_1->get_acl;
@entries = $a_1->all_entries;

foreach my $e ( @entries ) {
   print ref $e,   "\n";
   print $e->name, "\n";
}



print "\n";
print "MORE ACL Entry Objects for ", $db->expanded_path, "\n";
$a       = $db->get_acl;
@entries = $a->entries(qw(-Default- invalid_entry LocalDomainServers));
@names   = $a->all_entrynames;

print "got ", scalar( @entries ), " entries from 3 requested names\n";
print "total no. of entry names:   ", scalar @names,   "\n";

foreach my $e ( @entries ) {
   print ref $e,       "\n";
   print shift @names, "\n";
}



print "\n";
print "MORE ACL Entry Objects for ", $db_1->expanded_path, "\n";
$a2      = $db_1->get_acl;
@entries = $a2->entries(qw(invalid_entry LocalDomainServers -Default-));
@names   = $a2->all_entrynames;

print "got ", scalar( @entries ), " entries from 3 requested names\n";
print "total no. of entry names:   ", scalar @names,   "\n";
print "last debug print before global destruction\n";

foreach my $e ( @entries ) {
   print ref $e,       "\n";
   print shift @names, "\n";
}
