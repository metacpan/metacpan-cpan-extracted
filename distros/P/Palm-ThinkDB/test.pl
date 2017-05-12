# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Palm::PDB;
use Palm::ThinkDB;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Test 2
$pdb = new Palm::PDB;

#$Palm::ThinkDB::DEBUG = 1;

$pdb->Load('data/TD2_synctest.pdb');

my %foo;

$foo{type} = $pdb->{type};
$foo{name} = $pdb->{name};
$foo{creator} = $pdb->{creator};

my @records = $pdb->db_records;
my @columns = $pdb->columns;

#print "Columns: ", join(", ", @columns), "\n";

# foreach my $rec (@records) {
#     printf "Record %d\n", $rec->{idnum};
#     foreach my $col (@columns) {
#         printf "  %s = %s\n", $col, $pdb->get($rec, $col);
#     }
# }

$newrec = $pdb->append_Record;
$pdb->set($newrec,'a',100);
$pdb->set($newrec,'b',"This is a test, baby!");

$pdb->Write('data/newdb.pdb');

undef $pdb;

$pdb = new Palm::PDB;
$pdb->Load('data/newdb.pdb');

if ($foo{type} eq $pdb->{type}
    && $foo{name} eq $pdb->{name}
    && $foo{creator} eq $foo{creator}) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

my @newcol = $pdb->columns;
my $ok = 1;
for (my $i = 0; $i < @newcol; $i++) {
    if ($newcol[$i] ne $columns[$i]) {
        $ok = 0;
        last;
    }
}

if ($ok == 1) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

# That's it so far.
