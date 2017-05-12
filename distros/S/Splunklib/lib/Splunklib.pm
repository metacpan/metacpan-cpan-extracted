#
# $Id: Splunklib.pm,v 927d5bf7d37e 2015/10/03 12:57:38 gomor $
#
package Splunklib;
use strict;
use warnings;

our $VERSION = '0.23';

1;

__END__

=head1 NAME

Splunklib - the Splunk SDK to create custom commands in Perl

=head1 SYNOPSIS

   #
   # Simple base64 custom command to encode/decode Base64
   #
   use FindBin qw($Bin);
   use lib "$Bin/lib";

   use Splunklib::Intersplunk qw(readResults outputResults isGetInfo outputGetInfo);

   # GetInfo support
   # @ARGV example: "__GETINFO__ field=_raw action=encode"
   if (isGetInfo(\@ARGV)) {
      outputGetInfo(undef, \*STDOUT);
      exit(0);
   }

   # @ARGV example: "field=_raw action=encode"
   my $field = '_raw';    # Default to encode/decode _raw
   my $action = 'encode'; # Default to encode
   for my $arg (@ARGV) {
      my ($k, $v) = split(/=/, $arg);
      if    ($k eq 'field')  { $field  = $v; }
      elsif ($k eq 'action') { $action = $v; }
   }

   my $ary = readResults(\*STDIN, undef, 1);
   my $results = $ary->[0];
   my $header = $ary->[1];
   my $lookup = $ary->[2];

   use MIME::Base64;

   for my $result (@$results) {
      if ($action eq 'encode') {
         $result->[$lookup->{$new_field}] = encode_base64($result->[$lookup->{$field}], '');
      }
      else {
         $result->[$lookup->{$new_field}] = decode_base64($result->[$lookup->{$field}]);
      }
   }

   outputResults($ary, undef, undef, '\n', \*STDOUT);

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
