#
# $Id: SignatureP.pm 22 2015-01-04 16:42:47Z gomor $
#
package Net::SinFP3::Ext::DBI::SignatureP;
use strict;
use warnings;

use base qw(Net::SinFP3::Ext::DBI);

__PACKAGE__->table('SignatureP');
__PACKAGE__->columns(All => qw/
   idSignatureP
   trusted
   idIpVersion
   idSystemClass
   idVendor
   idOs
   idOsVersion
   idOsVersionFamily
   idPatternTcpFlags
   idPatternTcpWindow
   idPatternTcpOptions
   idPatternTcpMss
   idPatternTcpWScale
   idPatternTcpOLength
/);
__PACKAGE__->has_a(idIpVersion            => 'Net::SinFP3::Ext::DBI::IpVersion');
__PACKAGE__->has_a(idSystemClass          => 'Net::SinFP3::Ext::DBI::SystemClass');
__PACKAGE__->has_a(idVendor               => 'Net::SinFP3::Ext::DBI::Vendor');
__PACKAGE__->has_a(idOs                   => 'Net::SinFP3::Ext::DBI::Os');
__PACKAGE__->has_a(idOsVersion            => 'Net::SinFP3::Ext::DBI::OsVersion');
__PACKAGE__->has_many(idOsVersionChildren => 'Net::SinFP3::Ext::DBI::OsVersionChildren');
__PACKAGE__->has_a(idOsVersionFamily      => 'Net::SinFP3::Ext::DBI::OsVersionFamily');
__PACKAGE__->has_a(idPatternTcpFlags    => 'Net::SinFP3::Ext::DBI::PatternTcpFlags');
__PACKAGE__->has_a(idPatternTcpWindow   => 'Net::SinFP3::Ext::DBI::PatternTcpWindow');
__PACKAGE__->has_a(idPatternTcpOptions  => 'Net::SinFP3::Ext::DBI::PatternTcpOptions');
__PACKAGE__->has_a(idPatternTcpMss      => 'Net::SinFP3::Ext::DBI::PatternTcpMss');
__PACKAGE__->has_a(idPatternTcpWScale   => 'Net::SinFP3::Ext::DBI::PatternTcpWScale');
__PACKAGE__->has_a(idPatternTcpOLength  => 'Net::SinFP3::Ext::DBI::PatternTcpOLength');

1;

__END__


=head1 NAME

Net::SinFP3::Ext::DBI::SignatureP - SignatureP database table

=head1 DESCRIPTION

Go to http://www.networecon.com/tools/sinfp/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
