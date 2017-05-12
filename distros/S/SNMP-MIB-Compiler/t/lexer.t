# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;

print "1..10\n";
my $t = 1;

my $mib = new SNMP::MIB::Compiler();
$mib->{'filename'} = '<DATA>';
$mib->{'debug_lexer'} = 0;

# create a stream to the pseudo MIB file
my $s = Stream->new(*DATA);
$mib->{'stream'} = $s;

&test('word1');
&test('WORD2');
&test('foo-bar');
&test('FOO');
&test('bar');
&test('bat');
&test('foo-bar');
&test('bar-foo');
&test('PLUS-INFINITY');
&test('MINUS-INFINITY');

sub test {
  my $expect = shift;

  my ($res, $k) = $mib->yylex();
  $k = '', print scalar $mib->assert unless defined $k;
  print $res && $k eq $expect ? "" : "not ", "ok ", $t++, "\n";
  print "Got '$k' but '$expect' was expected\n" unless $k eq $expect;
}

# end

__DATA__

word1 WORD2 foo-bar FOO--BAR
bar -- BAZ -- bat
foo-bar--bar-baz--bar-foo
PLUS-INFINITY--
MINUS-INFINITY
