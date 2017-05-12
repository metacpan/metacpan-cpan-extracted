#!/usr/bin/perl -ws
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::Nibbler;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use lib "t";

{
package Parse::Nibbler;


###############################################################################
Register
( 'McCoy', sub
###############################################################################
  {
    AlternateRules( 'DeclareProfession', 'MedicalDiagnosis' );
  }
);


###############################################################################
# DeclareProfession : 
#    [Dammit,Gadammit] <name> , I'm a doctor not a [Bricklayer,Ditchdigger] !
###############################################################################
Register 
( 'DeclareProfession', sub 
###############################################################################
  {
    AlternateValues('Dammit', 'Gadammit');
    Name();
    ValueIs(",");
    ValueIs("Ima");
    ValueIs("doctor");
    ValueIs("not");
    ValueIs("a");
    AlternateValues('Bricklayer', 'Ditchdigger');
    ValueIs("!");
  }
);

###############################################################################
# MedicalDiagnosis : 
#    [He's,She's] dead, <name> !
###############################################################################
Register 
( 'MedicalDiagnosis', sub 
###############################################################################
  {
    my $p = shift;
    AlternateValues("He's", "She's");
    ValueIs("dead");
    ValueIs(",");
    Name();
    ValueIs("!");
  }
);

###############################################################################
Register 
( 'Name', sub 
###############################################################################
  {
    my $p = shift;
    AlternateValues( 'Jim', 'Scotty', 'Spock' );

  }
);



use Data::Dumper;


new('t/bones.txt');


McCoy();

print dumper;


print "ok 2\n";


} # end package MyGrammar
