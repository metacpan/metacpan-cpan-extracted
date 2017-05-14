# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }

use blib      '../Object'   ;     # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Name' ;

use        Notes::Session;     # note: inherits from Notes::Object
use        Notes::Name; 	  # note: inherits from Notes::Object

use        Devel::Peek;

   # Test 1 - checks wether (dyna)loading the (XS) module works
print "ok 1\n";
$loaded = 1;
END { print "not ok 1\n" unless $loaded; }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $s  = new Notes::Session;

my $name = $s->create_name('/C=GB/A=RN/P=Red Squadron/O=CAM/CN=Jayne Doe@FooDomain');

print 'Name: /C=GB/A=RN/P=Red Squadron/O=CAM/CN=Jayne Doe@FooDomain', "\n";
print "=" x 80, "\n";

print "Abbreviated:      ", $name->{Abbreviated},      "\n";
print "Addr821:          ", $name->{Addr821},          "\n";
print "Addr822LocalPart: ", $name->{Addr822LocalPart}, "\n";
print "Addr822Phrase:    ", $name->{Addr822Phrase},    "\n";
print "ADMD:             ", $name->{ADMD},             "\n";
print "Canonical:        ", $name->{Canonical},        "\n";
print "Common:           ", $name->{Common},           "\n";
print "Country:          ", $name->{Country},          "\n";
print "Domain:           ", $name->{Domain},           "\n";
print "Generation:       ", $name->{Generation},       "\n";
print "Given:            ", $name->{Given},            "\n";
print "Initials:         ", $name->{Initials},         "\n";
print "Language:         ", $name->{Language},         "\n";
print "Organization:     ", $name->{Organization},     "\n";
print "PRMD:             ", $name->{PRMD},             "\n";
print "Surname:          ", $name->{Surname},          "\n\n";

print "=" x 80, "\n";

Dump($name,25);

undef $name;
undef $s;

print "ok 2\n";