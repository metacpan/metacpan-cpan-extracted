#
# $Id: Signature.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::DB::Signature;
use strict;
use warnings;

require DBIx::SQLite::Simple::Table;
our @ISA = qw(DBIx::SQLite::Simple::Table);

our @AS = qw(
   idSignature
   trusted
   idIpVersion
   idSystemClass
   idVendor
   idOs
   idOsVersion
   idOsVersionFamily
   idP1PatternBinary
   idP1PatternTcpFlags
   idP1PatternTcpWindow
   idP1PatternTcpOptions
   idP1PatternTcpMss
   idP2PatternBinary
   idP2PatternTcpFlags
   idP2PatternTcpWindow
   idP2PatternTcpOptions
   idP2PatternTcpMss
   idP3PatternBinary
   idP3PatternTcpFlags
   idP3PatternTcpWindow
   idP3PatternTcpOptions
   idP3PatternTcpMss

   matchType
   matchMask
   ipVersion
   systemClass
   vendor
   os
   osVersion
   osVersionFamily

   sigP1H0
   sigP2H0
   sigP3H0
   sigP1H1
   sigP2H1
   sigP3H1
   sigP1H2
   sigP2H2
   sigP3H2
);
our @AA = qw(
   osVersionChildren
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

our $Id     = $AS[0];
our @Fields = @AS[1..$#AS-17];

1;

=head1 NAME

Net::SinFP::DB::Signature - Signature database table

=head1 DESCRIPTION

Go to http://www.gomor.org/sinfp to know more.

=cut

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
