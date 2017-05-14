require 5.001;

use Pilot::AddrBook;

if ($ARGV[0] eq "-p") {
    $file = $ARGV[1];
    $db   = new Pilot::AddrBook;
    %hash = ();

    read_db($db, $file, \%hash);

    foreach $key (sort keys %hash) {
        print "$key\n";
    }
    exit 0;
}

$b_pilot_file = shift @ARGV;
$b_pilot_db   = new Pilot::AddrBook;
%b_pilot_hash = ();

print "Reading (base) Pilot Address Book ...\n";

read_db($b_pilot_db, $b_pilot_file, \%b_pilot_hash);


$pilot_file   = shift @ARGV;
$pilot_db     = new Pilot::AddrBook;
%master_hash  = ();

print "Reading Pilot Address Book ...\n";

read_db($pilot_db, $pilot_file, \%master_hash);


$b_bbdb_file  = shift @ARGV;
$b_bbdb_db    = new Address::BBDB;
%b_bbdb_hash  = ();

print "Reading (base) BBDB file ...\n";

read_db($b_bbdb_db, $b_bbdb_file, \%b_bbdb_hash);


$bbdb_file    = shift @ARGV;
$bbdb_db      = new Address::BBDB;
%slave_hash   = ();

print "Reading BBDB file ...\n";

read_db($bbdb_db, $bbdb_file, \%slave_hash);

$bbdb_db->Merge(\%b_pilot_hash, \%master_hash, \%b_bbdb_hash, \%slave_hash, 1);

print "Writing new BBDB file ...\n";

$bbdb_db->Write($bbdb_file, \%master_hash, shift @ARGV);


#copy_file($bbdb_file, $b_bbdb_file);
copy_file($pilot_file, $b_pilot_file);


sub read_db {
    my ($db, $file, $ref) = @_;

    $db->Read($file,
    [ ".*",
      { "Object"       => $ref,
        "Keysep"       => "_",
        "Keyfields"    => [ "Last", "Middle", "First", "Title", "Company", "Category" ],
        "CustomFields" => [ "Middle", "birth-date", "status", "alert" ],
        "ArrayFields"  => [ "alert" ],
      }]);
}

sub copy_file {
    my ($src, $dest) = @_;
    system("copy $src $dest");
}
