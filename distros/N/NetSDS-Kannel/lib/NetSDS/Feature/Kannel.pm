#===============================================================================
#
#       MODULE:  NetSDS::Feature::Kannel
#
#  DESCRIPTION:  Kannel application feature
#
#       AUTHOR:  Michael Bochkaryov (RATTLER), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#
#===============================================================================

=head1 NAME

NetSDS::Feature::Kannel - kannel application feature

=head1 SYNOPSIS

	# *****************************************
	# Configuration file fragment

	<feature smsgw>
		class = NetSDS::Feature::Kannel
		sendsms_url = http://10.0.1.2:13013/cgi-bin/sendsms
		sendsms_user = netsds
		sendsms_passwd = topsecret
	</feture>
	

	# *****************************************
	# Application
	
	SMSApp->run(
		auto_features => 1,
	);

	package SMSApp;
	
	sub process {
		...
		$self->sms->send(
			from => '1234',
			to => '380501234567',
		);
	}

	1;

=head1 DESCRIPTION

C<NetSDS::Feature::Kannel> module provides pluggable API to Kannel
from NetSDS application.

=cut

package NetSDS::Feature::Kannel;

use 5.8.0;
use strict;
use warnings;

use NetSDS::Kannel;
use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = "1.300";

#===============================================================================

=head1 CLASS API

=over

=item B<new([...])>

Constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub init {

	my ( $class, $app, $conf ) = @_;

	my $kannel = NetSDS::Kannel->new(%{$conf});

	$app->log("info", "Kannel feature loaded...");

	return $kannel;

};


1;

__END__

=back

=head1 SEE ALSO

=over

=item * L<NetSDS::Kannel>

=item * L<NetSDS::Feature>

=item * L<NetSDS::App>

=item * L<http://www.kannel.org/>

=back

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

