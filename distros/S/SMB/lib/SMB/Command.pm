# SMB-Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
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

package SMB::Command;

use strict;
use warnings;

use parent 'SMB';

sub new ($$$$%) {
	my $class = shift;
	my $smb    = shift || die "No smb parameter in $class constructor\n";
	my $name   = shift || die "No name parameter in $class constructor\n";
	my $header = shift || die "No header parameter in $class constructor\n";
	my %options = @_;

	my $self = $class->SUPER::new(
		%options,
		smb  => $smb,
		name => $name,
		header => $header,
	);

	$self->init;

	return $self;
}

sub is ($$) {
	my $self = shift;
	my $name = shift || '';

	return $self->name eq $name;
}

sub is_response ($) {
	my $self = shift;

	return $self->header->is_response;
}

sub is_response_to ($$) {
	my $self = shift;
	my $request = shift || die;

	my $header1 = $request->header;
	my $header2 = $self->header;

	return
		!$header1->is_response &&
		$header2->is_response &&
		$header1->code == $header2->code &&
		$header1->mid  == $header2->mid;
}

sub is_smb1 ($) { $_[0]->smb <= 1 }
sub is_smb2 ($) { $_[0]->smb >= 2 }

sub status ($) { $_[0]->header->status }
sub set_status ($$) { $_[0]->header->status($_[1]); }
sub is_success ($) { $_[0]->status == 0 }
sub is_error   ($) { $_[0]->status != 0 }

# stub methods to be overloaded

sub parse ($$%) {
	my $self = shift;
	my $parser = shift;

	return $self;
}

sub pack ($$%) {
	my $self = shift;
	my $packer = shift;

	return $self;
}

sub init ($) {
}

# end of stub methods

sub set ($%) {
	my $self = shift;
	my %values = @_;

	$self->{$_} = $values{$_} for keys %values;
}

sub abort_pack ($$) {
	my $self = shift;
	my $packer = shift;
	my $status = shift;

	$self->set_status($status);
	$packer->jump('status')->uint32($status)->jump('command-start');

	return $self;
}

sub dump ($) {
	my $self = shift;

	return sprintf "SMB%d [%s %s] mid=%u uid=%x tid=%02x%s",
		$self->smb, $self->name,
		$self->is_response ? "Response" : "Request ",
		$self->header->mid,
		$self->header->uid,
		$self->header->tid,
		$self->status ? sprintf " status=%x", $self->status : '',
}

1;
