#
# $Id: Signature.pm 22 2015-01-04 16:42:47Z gomor $
#
package Net::SinFP3::Ext::DBI::Signature;
use strict;
use warnings;

use base qw(Net::SinFP3::Ext::DBI);

__PACKAGE__->table('Signature');
__PACKAGE__->columns(All => qw/
   idSignature
   trusted
   idIpVersion
   idSystemClass
   idVendor
   idOs
   idOsVersion
   idOsVersionFamily
   idS1PatternBinary
   idS1PatternTcpFlags
   idS1PatternTcpWindow
   idS1PatternTcpOptions
   idS1PatternTcpMss
   idS1PatternTcpWScale
   idS1PatternTcpOLength
   idS2PatternBinary
   idS2PatternTcpFlags
   idS2PatternTcpWindow
   idS2PatternTcpOptions
   idS2PatternTcpMss
   idS2PatternTcpWScale
   idS2PatternTcpOLength
   idS3PatternBinary
   idS3PatternTcpFlags
   idS3PatternTcpWindow
   idS3PatternTcpOptions
   idS3PatternTcpMss
   idS3PatternTcpWScale
   idS3PatternTcpOLength
/);
__PACKAGE__->has_a(idIpVersion            => 'Net::SinFP3::Ext::DBI::IpVersion');
__PACKAGE__->has_a(idSystemClass          => 'Net::SinFP3::Ext::DBI::SystemClass');
__PACKAGE__->has_a(idVendor               => 'Net::SinFP3::Ext::DBI::Vendor');
__PACKAGE__->has_a(idOs                   => 'Net::SinFP3::Ext::DBI::Os');
__PACKAGE__->has_a(idOsVersion            => 'Net::SinFP3::Ext::DBI::OsVersion');
__PACKAGE__->has_many(idOsVersionChildren => 'Net::SinFP3::Ext::DBI::OsVersionChildren');
__PACKAGE__->has_a(idOsVersionFamily      => 'Net::SinFP3::Ext::DBI::OsVersionFamily');
__PACKAGE__->has_a(idS1PatternBinary      => 'Net::SinFP3::Ext::DBI::PatternBinary');
__PACKAGE__->has_a(idS1PatternTcpFlags    => 'Net::SinFP3::Ext::DBI::PatternTcpFlags');
__PACKAGE__->has_a(idS1PatternTcpWindow   => 'Net::SinFP3::Ext::DBI::PatternTcpWindow');
__PACKAGE__->has_a(idS1PatternTcpOptions  => 'Net::SinFP3::Ext::DBI::PatternTcpOptions');
__PACKAGE__->has_a(idS1PatternTcpMss      => 'Net::SinFP3::Ext::DBI::PatternTcpMss');
__PACKAGE__->has_a(idS1PatternTcpWScale   => 'Net::SinFP3::Ext::DBI::PatternTcpWScale');
__PACKAGE__->has_a(idS1PatternTcpOLength  => 'Net::SinFP3::Ext::DBI::PatternTcpOLength');
__PACKAGE__->has_a(idS2PatternBinary      => 'Net::SinFP3::Ext::DBI::PatternBinary');
__PACKAGE__->has_a(idS2PatternTcpFlags    => 'Net::SinFP3::Ext::DBI::PatternTcpFlags');
__PACKAGE__->has_a(idS2PatternTcpWindow   => 'Net::SinFP3::Ext::DBI::PatternTcpWindow');
__PACKAGE__->has_a(idS2PatternTcpOptions  => 'Net::SinFP3::Ext::DBI::PatternTcpOptions');
__PACKAGE__->has_a(idS2PatternTcpMss      => 'Net::SinFP3::Ext::DBI::PatternTcpMss');
__PACKAGE__->has_a(idS2PatternTcpWScale   => 'Net::SinFP3::Ext::DBI::PatternTcpWScale');
__PACKAGE__->has_a(idS2PatternTcpOLength  => 'Net::SinFP3::Ext::DBI::PatternTcpOLength');
__PACKAGE__->has_a(idS3PatternBinary      => 'Net::SinFP3::Ext::DBI::PatternBinary');
__PACKAGE__->has_a(idS3PatternTcpFlags    => 'Net::SinFP3::Ext::DBI::PatternTcpFlags');
__PACKAGE__->has_a(idS3PatternTcpWindow   => 'Net::SinFP3::Ext::DBI::PatternTcpWindow');
__PACKAGE__->has_a(idS3PatternTcpOptions  => 'Net::SinFP3::Ext::DBI::PatternTcpOptions');
__PACKAGE__->has_a(idS3PatternTcpMss      => 'Net::SinFP3::Ext::DBI::PatternTcpMss');
__PACKAGE__->has_a(idS3PatternTcpWScale   => 'Net::SinFP3::Ext::DBI::PatternTcpWScale');
__PACKAGE__->has_a(idS3PatternTcpOLength  => 'Net::SinFP3::Ext::DBI::PatternTcpOLength');

1;

__END__


=head1 NAME

Net::SinFP3::Ext::DBI::Signature - Signature database table

=head1 DESCRIPTION

Go to http://www.networecon.com/tools/sinfp/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
