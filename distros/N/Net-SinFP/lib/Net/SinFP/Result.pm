#
# $Id: Result.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::Result;
use strict;
use warnings;

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

our @AS = qw(
   idSignature
   ipVersion
   systemClass
   vendor
   os
   osVersion
   osVersionFamily
   matchType
   matchMask
);
our @AA = qw(
   osVersionChildrenList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

1;

=head1 NAME

Net::SinFP::Result - contains all information about matched fingerprint

=head1 SYNOPSIS

   # A SinFP object has previously been created,
   # used, and some matches have been found

   for my $r ($sinfp->resultList) {

      print 'idSignature:     '.$r->idSignature    ."\n";
      print 'ipVersion:       '.$r->ipVersion      ."\n";
      print 'systemClass:     '.$r->systemClass    ."\n";
      print 'vendor:          '.$r->vendor         ."\n";
      print 'os:              '.$r->os             ."\n";
      print 'osVersion:       '.$r->osVersion      ."\n";
      print 'osVersionFamily: '.$r->osVersionFamily."\n";
      print 'matchType:       '.$r->matchType      ."\n";
      print 'matchMask:       '.$r->matchMask      ."\n";

      for ($r->osVersionChildrenList) {
         print "osVersionChildren: $_\n";
      }

      print "\n";
   }

=head1 DESCRIPTION

This module is the "result" object, used to ask SinFP which operating systems have matched by searching from the signature database.

=head1 ATTRIBUTES

=over 4

=item B<idSignature>

=item B<ipVersion>

=item B<systemClass>

=item B<vendor>

=item B<os>

=item B<osVersion>

=item B<osVersionFamily>

=item B<matchType>

=item B<matchMask>

Standard attributes, names are self explanatory.

=item B<osVersionChildrenList>

This one returns an array of OS version children. For example, if a Linux 2.6.x matches, you may have more known versions from this array (2.6.18, ...).

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
