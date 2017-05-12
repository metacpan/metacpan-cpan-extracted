#!/usr/bin/perl
use strict;
use warnings;

# Based on CLX code: https://splunkbase.splunk.com/app/1922/#/documentation

use FindBin qw($Bin);
use lib "$Bin/lib";

use Splunklib::Intersplunk qw(readResults outputResults isGetInfo outputGetInfo);

#
# Examples:
#
# index=local_system
# | base64pl field=_raw action=encode
# | eval b64_raw=_raw
# | base64pl field=_raw action=decode
#
# index=local_system
# | base64pl field=_raw action=encode

use Data::Dumper;
use MIME::Base64;

# GetInfo support
if (isGetInfo(\@ARGV)) {
   outputGetInfo(undef, \*STDOUT);
   exit(0);
}

# @ARGV example: field=_raw action=encode mode=replace
my $field = '_raw';    # Default to encode/decode _raw
my $action = 'encode'; # Default to encode
my $mode = 'replace';  # Default to replace
for my $arg (@ARGV) {
   my ($k, $v) = split(/=/, $arg);
   if ($k eq 'field') {
      $field = $v;
   }
   elsif ($k eq 'action') {
      $action = $v;
   }
   elsif ($k eq 'mode') {
      $mode = $v;
   }
}

my $ary = readResults(\*STDIN, undef, 1);
my $results = $ary->[0];
my $header = $ary->[1];
my $lookup = $ary->[2];

my $new_field;
if ($mode eq 'append') {
   $new_field = 'b64_'.$field;
}
else {
   $new_field = $field;
}

# Add the field if it does not exists
if (! exists($lookup->{$new_field})) {
   push @$header, $new_field;
   my $new = keys %$lookup;
   $lookup->{$new_field} = $new;
}

for my $result (@$results) {
   if ($action eq 'encode') {
      $result->[$lookup->{$new_field}] = encode_base64($result->[$lookup->{$field}], '');
   }
   else {
      $result->[$lookup->{$new_field}] = decode_base64($result->[$lookup->{$field}]);
   }
}

outputResults($ary, undef, undef, '\n', \*STDOUT);

exit(0);
