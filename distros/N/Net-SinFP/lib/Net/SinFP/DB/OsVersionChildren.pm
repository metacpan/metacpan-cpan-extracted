#
# $Id: OsVersionChildren.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::DB::OsVersionChildren;
use strict;
use warnings;

require DBIx::SQLite::Simple::Table;
our @ISA = qw(DBIx::SQLite::Simple::Table);

our @AS = qw(
   idSignature
   idOsVersion
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our @Fields = @AS;

1;

=head1 NAME

Net::SinFP::DB::OsVersionChildren - OsVersionChildren database table

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
