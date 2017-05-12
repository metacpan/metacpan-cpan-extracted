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

package SMB::Tree;

use strict;
use warnings;

use parent 'SMB';

use SMB::File;

sub new ($$$%) {
	my $class = shift;
	my $share = shift || die "No share in constructor";
	my $id    = shift || die "No tree id in constructor";
	my %options = @_;

	$options{addr} //= undef;  # remote
	$options{root} //= undef;  # local

	my $self = $class->SUPER::new(
		%options,
		share => $share,
		id    => $id,
	);

	die "Neither 'root' for local tree nor 'addr' for remote tree in constructor"
		unless $self->is_local || $self->is_remote;

	return $self;
}

sub is_ipc ($) {
	my $self = shift;

	return $self->share eq 'IPC$';
}

sub is_local ($) {
	my $self = shift;

	return $self->root || $self->is_ipc;
}

sub is_remote ($) {
	my $self = shift;

	return $self->addr && $self->client;
}

sub perform_remote_command ($$@) {
	my $self = shift;
	my $command = shift;

	die unless $self->is_remote;

	$self->client->perform_tree_command($self, $command, @_);
}

sub chdir  { shift()->perform_remote_command('chdir',  @_); }
sub find   { shift()->perform_remote_command('find',   @_); }
sub dnload { shift()->perform_remote_command('dnload', @_); }
sub upload { shift()->perform_remote_command('upload', @_); }
sub copy   { shift()->perform_remote_command('copy',   @_); }
sub rename { shift()->perform_remote_command('rename', @_); }
sub remove { shift()->perform_remote_command('remove', @_); }

1;
