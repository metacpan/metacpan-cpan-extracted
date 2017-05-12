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

my $good = { 'type' => 'OBJECT-TYPE',
	     'access' => 'read-only',
	     'oid' => [ 'foo', 1 ],
	     'description' => '" "',
	     'status' => 'mandatory',
	     'syntax' => { 'type' => 'INTEGER' }};

print Compare($mib->{'nodes'}{'bar'},
	      $good) ? "" : "not ", "ok ", $t++, "\n";

# end

__DATA__

-- test the bar node to be sure that "FOO-MIB-1-0-3" has been
-- successfully read.

FOO-MIB-1-0-3 DEFINITIONS ::= BEGIN

 bar OBJECT-TYPE
        SYNTAX INTEGER
        ACCESS read-only
        STATUS mandatory
        DESCRIPTION
             " "
        ::= { foo 1 }

END
