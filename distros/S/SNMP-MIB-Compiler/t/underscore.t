# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;
$| = 1;

print "1..1\n";
my $t = 1;

my $mib = new SNMP::MIB::Compiler();
$mib->{'filename'} = '<DATA>';
$mib->{'debug_lexer'} = 0;
$mib->{'allow_underscore'} = 1;

# create a stream to the pseudo MIB file
my $s = Stream->new(*DATA);
$mib->{'stream'} = $s;
$mib->parse_Module;

my $good = { 1 => 'noUnderscore', 2 => 'with_underscore' };

print Compare($mib->{'nodes'}{'underScore'}{'syntax'}{'values'},
	      $good) ? "" : "not ", "ok ", $t++, "\n";

# end

__DATA__

UNDERSCORE-MIB DEFINITIONS ::= BEGIN

 underScore OBJECT-TYPE
        SYNTAX  INTEGER {
                     noUnderscore(1),
                     with_underscore(2)
                }
        ACCESS read-only
        STATUS mandatory
        DESCRIPTION
             " "
        ::= { under 1 }

END
