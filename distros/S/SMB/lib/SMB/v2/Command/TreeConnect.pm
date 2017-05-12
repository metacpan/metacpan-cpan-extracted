# SMB Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB::v2::Command::TreeConnect;

use strict;
use warnings;

use parent 'SMB::v2::Command';

sub init ($) {
	$_[0]->set(
		share_type   => 1,
		share_flags  => 0x800,
		capabilities => 0,
		access_mask  => 0x1f01ff,
		uri          => undef,
	)
}

sub verify_uri ($) {
	my $self = shift;

	die "Tree connect $self misses share uri\n"
		unless $self->parse_share_uri($self->uri);

	return $self->uri;
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		$self->share_type($parser->uint8);
		$parser->uint8;  # reserved
		$self->share_flags($parser->uint32);
		$self->capabilities($parser->uint32);
		$self->access_mask($parser->uint32);
	} else {
		$parser->uint16;  # reserved
		$parser->uint16;
		my $uri_len = $parser->uint16;
		$self->uri($parser->utf16($uri_len));
	}

	return $self;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	if ($self->is_response) {
		$packer
			->uint8($self->share_type)
			->uint8(0)  # reserved
			->uint32($self->share_flags)
			->uint32($self->capabilities)
			->uint32($self->access_mask)
		;
	} else {
		$packer
			->uint16(0)  # reserved
			->uint16($packer->diff('smb-header') + 4)
			->stub('uri-len', 'uint16')
			->mark('uri')
			->utf16($self->verify_uri)
			->fill('uri-len', $packer->diff('uri'))
		;
	}
}

1;
