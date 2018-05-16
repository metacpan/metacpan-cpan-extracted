# SMB Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
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

package SMB::Server;

use strict;
use warnings;

use parent 'SMB::Agent';

use File::Basename qw(basename);
use SMB::Tree;
use SMB::DCERPC;
use SMB::v2::Command::Negotiate;
use SMB::v2::Command::Create;
use SMB::v2::Command::QueryInfo;
use SMB::v2::Command::QueryDirectory;
use SMB::v2::Command::Ioctl;

sub new ($%) {
	my $class = shift;
	my %options = @_;

	my $share_roots   = delete $options{share_roots};
	my $port          = delete $options{port};
	my $fifo_filename = delete $options{fifo_filename};

	die "Neither port nor fifo-filename is specified for $class\n"
		unless $port || $fifo_filename;

	my $main_socket = $fifo_filename
		? IO::Socket::UNIX->new(Listen => 1, Local => $fifo_filename)
		: IO::Socket::INET->new(Listen => 1, LocalPort => $port, Reuse => 1);

	my $listen_label = $fifo_filename ? "fifo $fifo_filename" : "port $port";
	die "Can't open $listen_label: $!\n" unless $main_socket;

	$options{passwd_filename} //= "$FindBin::Bin/../conf/passwd.txt";

	my $self = $class->SUPER::new(
		%options,
		main_socket => $main_socket,
		client_id   => 0,  # running index
	);

	$self->socket_pool->add($main_socket);

	if (!$share_roots && $FindBin::Bin) {
		my $shares_dir = "$FindBin::Bin/../shares";
		$share_roots = { map { basename($_) => $_ } grep { -d $_ && -x _ && -r _ } glob("$shares_dir/*") }
			if -d $shares_dir;
	}
	unless ($share_roots) {
		$self->err("No share_roots specified and no shares/ autodetected");
		$share_roots = {};
	} elsif (ref($share_roots) eq '' && $share_roots eq '-') {
		# special syntax to request a share-less server, don't complain
		$share_roots = {};
	} elsif (ref($share_roots) ne 'HASH') {
		$self->err("Invalid share_roots ($share_roots) specified");
		$share_roots = {};
	} elsif (!%$share_roots) {
		$self->err("No shares to manage, specify non-empty share_roots hash");
	}
	$self->{share_roots} = $share_roots;

	$self->msg("$class started, listening on $listen_label");

	return $self;
}

sub on_connect ($$) {
	my $self = shift;
	my $connection = shift;

	# intended to be overriden in sub-classes

	my $auth = $connection->auth;
	$auth->load_user_passwords($self->passwd_filename)
		or $auth->user_passwords({ test => '12345' });
}

sub on_disconnect ($$) {
	my $self = shift;
	my $connection = shift;

	# intended to be overriden in sub-classes
}

sub recv_command ($$) {
	my $self = shift;
	my $connection = shift;

	return $connection->recv_command;
}

sub on_command ($$$) {
	my $self = shift;
	my $connection = shift;
	my $command = shift;

	my $tid = $command->header->tid;
	my $tree = $tid ? (grep { $_->id == $tid } @{$connection->{trees}})[0] : undef;
	$command->{tree} = $tree if $tree;

	if ($command->is_smb1) {
		if ($command->is('Negotiate')) {
			if ($command->supports_smb_dialect(0x0202)) {
				$command = SMB::v2::Command::Negotiate->new_from_v1($command);
				$tid = 0;
			} else {
				$self->err("Client does not support SMB2, and we do not support SMB1, stopping");
			}
		}
	}

	if ($command->is_smb2) {
		my $error = 0;
		my $fid = $command->{fid};
		my $openfile = undef;

		if (($tid || exists $command->{fid}) && !$tree) {
			$error = SMB::STATUS_SMB_BAD_TID;
		}
		elsif ($command->is('Ioctl') && $command->function == SMB::v2::Command::Ioctl::FSCTL_DFS_GET_REFERRALS) {
			$error = SMB::STATUS_NOT_FOUND;
		}
		elsif ($command->is('Ioctl') && $command->function == SMB::v2::Command::Ioctl::FSCTL_PIPE_WAIT) {
			$error = SMB::STATUS_OBJECT_NAME_NOT_FOUND;
		}
		elsif ($fid) {
			if ($command->header->is_chained) {
				$fid = $connection->chain_fid if $connection->chain_fid && $command->is_fid_unset($fid);
			} else {
				$connection->chain_fid(undef);
			}
			$openfile = $connection->{openfiles}{$fid->[0], $fid->[1]}
				or $error = SMB::STATUS_FILE_CLOSED;
			$command->openfile($openfile);
		}

		if ($error) {
			# skip command processing
		}
		elsif ($command->is('Negotiate')) {
			$command->security_buffer($connection->auth->generate_spnego(is_initial => 1));
		}
		elsif ($command->is('SessionSetup')) {
			$connection->auth->process_spnego($command->security_buffer);
			$command->security_buffer($connection->auth->generate_spnego);
			$command->header->uid($connection->id);
			my $auth_completed = $connection->auth->auth_completed;
			$error = SMB::STATUS_LOGON_FAILURE
				if !$command->security_buffer
				|| defined $auth_completed && !$auth_completed;
		}
		elsif ($command->is('TreeConnect')) {
			my ($addr, $share) = $self->parse_share_uri($command->verify_uri);
			my $tree_root = $self->share_roots->{$share};
			if ($tree_root || $share eq 'IPC$') {
				my $tid = $command->header->tid(@{$connection->{trees}} + 1);
				$tree = SMB::Tree->new($share, $tid, root => $tree_root);
				push @{$connection->{trees}}, $tree;
				$command->tree($tree);
			} else {
				$error = SMB::STATUS_BAD_NETWORK_NAME;
			}
		}
		elsif ($command->is('Create')) {
			my $file = SMB::File->new(
				name => $command->file_name,
				share_root => $tree->root,
				is_ipc => $tree->is_ipc,
				is_directory => $command->requested_directory,
			);
			my $disposition = $command->disposition;
			if ($file->exists && $disposition == SMB::File::DISPOSITION_OPEN) {
				if ($command->requested_directory && !$file->is_directory) {
					$error = SMB::STATUS_NOT_A_DIRECTORY;
				} elsif ($command->requested_non_directory && $file->is_directory) {
					$error = SMB::STATUS_FILE_IS_A_DIRECTORY;
				}
			}
			unless ($error) {
				$openfile = $file->open_by_disposition($disposition);
				if ($openfile) {
					$openfile->{dcerpc} = SMB::DCERPC->new(name => $file->name)
						if $file->is_svc;
					$fid = [ ++$connection->{last_fid}, 0 ];
					$connection->chain_fid($fid) if $command->has_next_in_chain;
					$connection->{openfiles}{$fid->[0], $fid->[1]} = $openfile;
					$command->fid($fid);
					$command->openfile($openfile);
					$openfile->delete_on_close(1) if $command->requested_delete_on_close;
				} else {
					$error = SMB::STATUS_NO_SUCH_FILE;
				}
			}
		}
		elsif ($command->is('Close')) {
			if ($openfile->delete_on_close) {
				my $filename = $openfile->file->filename;
				$self->msg("Removing $filename");
				$openfile->file->remove()
					or $self->err("Failed to remove $filename: $!");
			}
			$openfile->close;
			delete $connection->{openfiles}{$fid->[0], $fid->[1]};
		}
		elsif ($command->is('QueryInfo')) {
			$command->prepare_info(quiet => $self->quiet);
		}
		elsif ($command->is('SetInfo')) {
			my $rename_info = $command->requested_rename_info;
			if ($rename_info) {
				my $filename1 = $openfile->file->filename;
				my $filename2 = $rename_info->{new_name} // die;
				my $replace   = $rename_info->{replace} // die;
				$self->msg("Renaming $filename1 to $filename2");
				($error, my $message) = $openfile->file->rename($filename2);
				$self->err("Failed to rename $filename1 to $filename2: $message")
					if $error;
			}
			$openfile->delete_on_close(1) if $command->requested_delete_on_close;
		}
		elsif ($command->is('Read')) {
			if ($openfile->{dcerpc}) {
				($command->{buffer}, $error) = $openfile->dcerpc->generate_packet;
			}
			else {
				$command->{buffer} = $openfile->read(
					length => $command->{length},
					offset => $command->{offset},
					minlen => $command->{minimum_count},
					remain => $command->{remaining_bytes},
					quiet  => $self->quiet,
				);
				$error = SMB::STATUS_END_OF_FILE unless defined $command->{buffer};
			}
		}
		elsif ($command->is('Write')) {
			if ($openfile->{dcerpc}) {
				$error = $openfile->dcerpc->process_packet($command->buffer);
			}
			else {
				$error = SMB::STATUS_NOT_IMPLEMENTED;
			}
		}
		elsif ($command->is('Ioctl')) {
			if ($openfile->{dcerpc}) {
				$error = $openfile->dcerpc->process_rpc_request($command->buffer);
				unless ($error) {
					(my $payload, $error) = $openfile->dcerpc->generate_rpc_response;
					$command->buffer($payload) unless $error;
				}
			}
			else {
				$error = SMB::STATUS_NOT_IMPLEMENTED;
			}
		}
		elsif ($command->is('QueryDirectory')) {
			my $start_idx = $command->is_reopen ? 0 : $command->is_index_specified
				? $command->file_index : $openfile->last_index;
			$command->{files} = $openfile->file->find_files(
				pattern => $command->file_pattern,
				start_idx => $start_idx,
				reopen => $command->is_reopen,
				quiet => $self->quiet,
			);
			$error = SMB::STATUS_INVALID_PARAMETER unless defined $command->{files};
		}
		elsif ($command->is('ChangeNotify')) {
			$command->header->aid(++$connection->{last_aid});
			$error = SMB::STATUS_PENDING;
		}
		elsif ($command->is('Cancel')) {
			$command->header->code($SMB::v2::Commands::command_codes{'ChangeNotify'});
			$error = SMB::STATUS_CANCELLED;
		}
		$command->prepare_response;
		$command->set_status($error) if $error;
		$connection->send_command($command);
		return;
	}

	$self->msg("Command $command ignored; missing functionality");
}

sub run ($) {
	my $self = shift;

	my $socket_pool = $self->socket_pool;
	my $connections = $self->connections;

	while (my @ready_sockets = $socket_pool->can_read) {
		foreach my $socket (@ready_sockets) {
			if ($socket == $self->main_socket) {
				my $client_socket = $socket->accept || next;
				my $connection = $self->add_connection(
					$client_socket, ++$self->{client_id},
					trees     => [],
					last_aid  => 0,
					last_fid  => 0,
					chain_fid => undef,
					openfiles => {},
				);
				unless ($connection) {
					$socket->close;
					next;
				}
				$self->on_connect($connection);
			}
			else {
				my $connection = $self->get_connection($socket)
					or die "Unexpected data on unmanaged $socket";
				my @commands = $socket->eof
					? $connection->msg("Connection reset by peer")
					: $self->recv_command($connection);
				if (!@commands) {
					$self->on_disconnect($connection);
					$self->delete_connection($connection);
					next;
				}
				for my $command (@commands) {
					$self->on_command($connection, $command);
				}
			}
		}
	}
}

1;
