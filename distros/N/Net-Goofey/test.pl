BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use strict;
no strict 'vars';
use diagnostics;

use Net::Goofey;
$loaded = 1;
print "ok 1\n";

print "You cannot do these tests unless you already have a Goofey login.\n\n";
print "If you don't have a Goofey login name and password, press ^C now.\n";

print "Enter your Goofey username: ";
my $goofeyname = <STDIN>;
chomp $goofeyname;

print "Enter your Goofey password: ";
my $goofeypassword = <STDIN>;
chomp $goofeypassword;

# Connect
my $Goofey = Net::Goofey->new($goofeyname, $goofeypassword);
if ($Goofey) {
   print "ok 2\n";
} else {
   print "not ok 2\n";
}

if ($Goofey->who("bekj")) {
   print "ok 3\n";
} else {
   print "not ok 3\n";
}

$Goofey = Net::Goofey->new($goofeyname, $goofeypassword);
chomp(my $whoami = `whoami`);
chomp(my $uname = `uname -a`);
if ($Goofey->send("bekj", "$whoami tested Net::Goofey on $uname")) {
   print "ok 4\n";
} else {
   print "not ok 4\n";
}

