#!/usr/bin/perl -w

# $Id: authortest.pl,v 1.4 2004/12/16 21:52:00 quinn Exp $

use strict;
use warnings;
use Net::Z3950::RadioMARC;

my $pattern = 'rmFFF1S11r'; # This is the type of tokens we're using
my $atributes = '@attr 1=1003 @attr 2=3 @attr 3=3 @attr 4=2 @attr 5=100 @attr 6=1';

set host => 'research.lis.unt.edu', port => '2200', db => 'zinterop';
set delay => 0;
set identityField => '001';
set verbosity => 1;

add 'record.mrc';

if (test('@attr 1=4 rm2451a11r', {ok=>''}) ne 'ok') {
  print "Test record not found in database -- unable to continue\n";
  exit 1;
}

my @author_fields = (
  '100$a',
  '100$d',
  '245$c',
  '700$a',
  '700$d',
  '710$a'
);

# this function returns a MARC token for field$subfield in
# the global $pattern

sub radtoken {
  $_ = shift;
  my $ret = $pattern;

  my ($field, $subfield) = /(...)\$(.)/;
  $ret =~ s/FFF/$field/;
  $ret =~ s/S/$subfield/;
  return $ret;
}

foreach (@author_fields) {
  my $search = "$atributes " . radtoken $_;
  test $search, {
    ok=>"1=1003 searches $_",
    notfound=>"1=1003 DOES NOT match $_"
  };
}
