#!/usr/bin/perl

# Test the parsing of individual attributes

# $Id: packdict.t 37 2006-11-14 01:42:55Z lem $

use IO::File;
use Test::More tests => 30;
use Data::Dumper;
use Net::Radius::Dictionary;

my $dictfile = "dict$$.tmp";

END 
{
    unlink $dictfile;
};

{
   my $dict;
   eval { $dict = Net::Radius::Dictionary->new() };
   isa_ok($dict, 'Net::Radius::Dictionary');
   ok(!$@, 'No errors during parse');
   diag $@ if $@;

   # Test presence of some stuff
   my %number_for = $dict->packet_numbers();
   is(scalar(keys %number_for), 35, 'Default packet numbers number');
   is($number_for{'Disconnect-NAK'}, 42, 'Simple mapping presence in hash');

   my %name_for = $dict->packet_names();
   is(scalar(keys %name_for), 34, 'Default packet names number');
   is($name_for{40}, 'Disconnect-Request', 'Simple mapping presence in hash');
   is($name_for{6}, 'Interim-Accounting', 
      'Back-resolution of 6 to Interim Accounting as default');

   # Direct resolution
   ok($dict->packet_hasname('Access-Reject'), 
      'packet_hasname() to default');
   is($dict->packet_num('Access-Reject'), 3, 'packet_num() to default');
   ok($dict->packet_hasnum(2), 'packet_hasnum() to default');
   is($dict->packet_name(2), 'Access-Accept', 'packet_name() to default');

   ok(! $dict->packet_hasname('@@Inexistent@@'), 
      'packet_hasname() on inexistent');
   is($dict->packet_num('@@Inexistent@@'), undef, 
      'packet_num() on inexistent');
   ok(! $dict->packet_hasnum(-1), 'packet_hasnum() on inexistent');
   is($dict->packet_name(-1), undef, 'packet_name() on inexistent');
}

{
   my $dict_content = do { local $/; <DATA>; };
   _write($dict_content);
   
   my $dict;
   eval { $dict = Net::Radius::Dictionary->new($dictfile) };
   isa_ok($dict, 'Net::Radius::Dictionary');
   ok(!$@, 'No errors during parse');
   diag $@ if $@;

   # Test presence of some stuff
   my %number_for = $dict->packet_numbers();

   is(scalar(keys %number_for), 10, 'Packet numbers number');
   is($number_for{'My-Experiment'}, 250, 'Simple mapping presence in hash');

   my %name_for = $dict->packet_names();
   is(scalar(keys %name_for), 10, 'Packet names number');
   is($name_for{1}, 'Access-Request', 'Simple mapping presence in hash');
   is($name_for{250}, 'My-Experiment', 'Experimental value');

   # Direct resolution
   ok($dict->packet_hasname('Access-Reject'), 
      'packet_hasname() to default');
   is($dict->packet_num('Access-Reject'), 3, 'packet_num() to default');
   ok($dict->packet_hasnum(2), 'packet_hasnum() to default');
   is($dict->packet_name(2), 'Access-Accept', 'packet_name() to default');

   ok(! $dict->packet_hasname('Disconnect-Request'), 
      'packet_hasname() on inexistent');
   is($dict->packet_num('Disconnect-NAK'), undef, 
      'packet_num() on inexistent');
   ok(! $dict->packet_hasnum(41), 'packet_hasnum() on inexistent');
   is($dict->packet_name(41), undef, 'packet_name() on inexistent');
}

sub _write
{
    my $dict = shift;
    my $fh = new IO::File;
    $fh->open($dictfile, "w") or diag "Failed to write dict $dictfile: $!";
    print $fh $dict;
    $fh->close;
}

__END__
# Sample dictionary
PACKET Access-Request 1
PACKET Access-Accept  2
PACKET Access-Reject  3
PACKET Accounting-Request   4
PACKET Accounting-Response  5
PACKET Accounting-Status    6
PACKET Access-Challenge    11
PACKET Status-Server       12
PACKET Status-Client       13
PACKET My-Experiment      250
