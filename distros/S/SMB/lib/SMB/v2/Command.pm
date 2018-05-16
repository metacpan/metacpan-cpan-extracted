# SMB-Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
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

package SMB::v2::Command;

use strict;
use warnings;

use parent 'SMB::Command';

use SMB::v2::Header;

use if (1 << 32 == 1), 'bigint';  # support native uint64 on 32-bit platforms

sub new ($$%) {
	my $class = shift;
	my $header = shift || '';
	my %options = @_;

	die "Invalid sub-class $class, should be SMB::v2::Command::*"
		unless $class =~ /^SMB::v2::Command::(\w+)/;

	die "Invalid header '$header', should be isa SMB::v2::Header"
		unless $header && $header->isa('SMB::v2::Header');

	my $self = $class->SUPER::new(
		2, $1, $header,
		%options,
	);

	return $self;
}

sub abort_pack ($$) {
	my $self = shift;
	my $packer = shift;
	my $status = shift;

	$self->set_status($status);
	$packer
		->jump('status')->uint32($status)
		->jump('command-start')->uint16(9)
	;

	return $self;
}

sub prepare_response ($) {
	my $self = shift;

	$self->header->{flags} |= SMB::v2::Header::FLAGS_RESPONSE;
	$self->header->{flags} |= SMB::v2::Header::FLAGS_ASYNC_COMMAND if $self->header->aid;
	$self->header->credits(31) if $self->header->credits > 31;
}

sub has_next_in_chain ($) {
	my $self = shift;

	return $self->header->chain_offset ? 1 : 0;
}

sub is_valid_fid ($) {
	my $self = shift;
	my $fid = shift;

	return ref($fid) eq 'ARRAY' && @$fid == 2
		&& defined $fid->[0] && $fid->[0] =~ /^\d+$/
		&& defined $fid->[1] && $fid->[1] =~ /^\d+$/;
}

sub is_fid_filled ($$$) {
	my $self = shift;
	my $fid = shift;
	my $pattern32 = shift;

	return
		($fid->[0] & 0xffffffff) == $pattern32 &&
		($fid->[0] >> 32)        == $pattern32 &&
		($fid->[1] & 0xffffffff) == $pattern32 &&
		($fid->[1] >> 32)        == $pattern32;
}

sub is_fid_unset ($$) {
	my $self = shift;
	my $fid = shift;

	return $self->is_fid_filled($fid, 0xffffffff);
}

sub is_fid_null ($$) {
	my $self = shift;
	my $fid = shift;

	return $self->is_fid_filled($fid, 0);
}

1;
