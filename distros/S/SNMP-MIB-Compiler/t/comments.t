# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;

print "1..7\n";
my $t = 1;

my $mib = new SNMP::MIB::Compiler();
$mib->{'filename'} = '<DATA>';
$mib->{'debug_lexer'} = 0;

# create a stream to the pseudo MIB file
my $s = Stream->new(*DATA);
$mib->{'stream'} = $s;

&test('foo');
&test('bar');
&test('baz');
&test('-');
&test('bat');
&test('foo');
&test('foo');

sub test {
  my $expect = shift;

  my ($res, $k) = $mib->yylex();
  $k = '', print scalar $mib->assert  unless defined $k;
  print $res && $k eq $expect ? "" : "not ", "ok ", $t++, "\n";
  print "Got '$k' but '$expect' was expected\n" unless $k eq $expect;
}

# end

__DATA__

-- an empty comment
--
foo

-- the comment only contains a "-"
---
bar

-- an empty enclosed comment
----
baz

-- a real "-" after an empty enclosed comment
-----
bat
------
foo
-- FOO -- foo
