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

package SMB::Client;

use strict;
use warnings;

use parent 'SMB::Agent';

use SMB::v2::Commands;
use SMB::v2::Command::Negotiate;
use SMB::v2::Command::SessionSetup;
use SMB::v2::Command::TreeConnect;
use SMB::v2::Command::Create;
use SMB::v2::Command::Close;
use SMB::v2::Command::QueryDirectory;
use SMB::v2::Command::Read;
use SMB::v2::Command::Write;
use SMB::Tree;

sub new ($$%) {
	my $class = shift;
	my $share_uri = shift;
	my %options = @_;

	my $verbose = delete $options{verbose} || 0;
	$options{quiet} = 1 unless $verbose;

	my $self = $class->SUPER::new(
		%options,
		server_id => 0,  # running index
		curr_conn_key => undef,  # key in connections hash
		unique_conn_addr => 1,
	);

	$self->connect($share_uri, %options)
		if $share_uri;

	return $self;
}

sub connect ($$%) {
	my $self = shift;
	my $share_uri = shift;
	my %options = @_;

	my ($addr, $share) = $share_uri =~ m![/\\]!
		? $self->parse_share_uri($share_uri)
		: ($share_uri);
	die "Please specify share uri //server.name.or.ip[:port]/share or server.name.or.ip[:port]\n"
		unless $addr;
	$addr .= ':445' unless $addr =~ /:/;

	my $socket = IO::Socket::INET->new(PeerAddr => $addr, Proto => 'tcp')
		or	die "Can't open $addr: $!\n";

	if ($options{just_socket}) {
		$self->{socket} = $socket;
	} else {
		my ($conn_key) = $self->add_connection(
			$socket, --$self->{server_id},
			addr     => $addr,
			share    => $share,
			username => $options{username},
			password => $options{password},
			tree     => undef,
			cwd      => '',
			openfiles => {},
			dialect      => undef,
			session_id   => 0,
			message_id   => 0,
			sent_request => undef,
		);

		$self->curr_conn_key($conn_key);
	}

	return $self;
}

sub get_curr_connection ($) {
	my $self = shift;

	my $connections = $self->connections;
	unless (%$connections) {
		$self->err("Called get_curr_connection when no connections established");
		return;
	}

	my $connection = $connections->{$self->curr_conn_key};
	unless ($connection) {
		$self->err("Called get_curr_connection when curr_conn_key is invalid");
		return;
	}

	return $connection;
}

sub find_connection_by_tree ($$) {
	my $self = shift;
	my $tree = shift // die;

	for (values %{$self->connections}) {
		return $_ if $_->tree == $tree;
	}

	$self->err("Can't find connection for $tree");
	return;
}

sub process_request ($$$%) {
	my $self = shift;
	my $connection = shift;
	my $command_name = shift;
	my %command_options = @_;

	my $command_class = "SMB::v2::Command::$command_name";
	my $command_code = $SMB::v2::Commands::command_codes{$command_name};
	my $no_warn = delete $command_options{_no_warn};

	my $request = $command_class->new(
		SMB::v2::Header->new(
			mid  => $connection->{message_id}++,
			uid  => $connection->session_id,
			tid  => $connection->tree ? $connection->tree->id : 0,
			code => $command_code,
		),
	);
	$request->set(%command_options);

	$connection->send_command($request);
	$connection->sent_request($request);

	my $response = $self->wait_for_response($connection);

	warn "SMB Error on $command_name response: " . ($response ? sprintf "%x", $response->status : "internal") . "\n"
		if !$no_warn && (!$response || $response->is_error);

	return $response;
}

sub process_negotiate_if_needed ($$) {
	my $self = shift;
	my $connection = shift;

	return 1 if $connection->dialect;

	my $response = $self->process_request($connection, 'Negotiate');
	if ($response && $response->is_success) {
		unless ($connection->auth->process_spnego($response->security_buffer)) {
			$self->err("Server does not support our negotiation mechanism, expect problems on SessionSetup");
		}
		$connection->dialect($response->dialect);
		return 1;
	}

	return 0;
}

sub process_sessionsetup_if_needed ($$) {
	my $self = shift;
	my $connection = shift;

	return 1 if $connection->session_id;

	my $response = $self->process_request($connection, 'SessionSetup',
		security_buffer => $connection->auth->generate_spnego,
		_no_warn => 1,
	);
	my $more_processing = $response->status == SMB::STATUS_MORE_PROCESSING_REQUIRED;
	return 0
		unless $response && ($response->is_success || $more_processing)
		&& $connection->auth->process_spnego($response->security_buffer);
	$connection->session_id($response->header->uid);
	return 1 if $response->is_success;
	return 0 unless $more_processing;

	$response = $self->process_request($connection, 'SessionSetup',
		security_buffer => $connection->auth->generate_spnego(
			username => $connection->username,
			password => $connection->password,
		),
	);
	if ($response && $response->is_success && $connection->auth->process_spnego($response->security_buffer)) {
		die "Got different session id on second SessionSetup"
			unless $connection->session_id == $response->header->uid;
		return 1;
	}

	return 0;
}

sub check_session ($$) {
	my $self = shift;
	my $connection = shift;

	return
		$self->process_negotiate_if_needed($connection) &&
		$self->process_sessionsetup_if_needed($connection);
}

sub connect_tree ($%) {
	my $self = shift;
	my %options = @_;

	my $connection = $self->get_curr_connection || return;

	my ($addr, $share, $username, $password) =
		map { $connection->{$_} || $options{$_} || die "No $_ to connect_tree\n" }
		qw(addr share username password);

	return unless $self->check_session($connection);

	$addr =~ s/:\d+//;
	my $response = $self->process_request($connection, 'TreeConnect', uri => "\\\\$addr\\$share");
	if ($response && $response->is_success) {
		my $tree = SMB::Tree->new(
			$share, $response->header->tid,
			addr   => $addr,
			client => $self,
			cwd    => '',
		);
		$connection->tree($tree);
		return $tree;
	}

	return;
}

sub _normalize_path ($$;$) {
	my $path = shift // '';
	my $base = shift // '';
	my $to_dos = shift || 0;

	$path = "$base/$path" if $path =~ m!^[^/]!;

	$path =~ s![/\\]+$!/!g;  # to unix
	# remove "./", "any/../", "../.." at the end
	while ($path =~ s=(^|/)\.(?:/|$)=$1=g) {}
	while ($path =~ s=(^|/)(?!\.\./)[^/]+/\.\.(?:/|$)=$1=g) {}
	$path =~ s!(?:(?:^|/)\.\.)+/?$!!;
	$path =~ s!/$!!;

	if ($to_dos) {
		$path =~ s=^/==;
		$path =~ s=/=\\=g;
	}

	return $path;
}

sub _basename ($;$) {
	my $path = shift // '';
	my $is_dos = shift || 0;

	my $delim = $is_dos ? '\\' : '/';

	return $path =~ /.*\Q$delim\E(.*)/ ? $1 : $path;
}

sub perform_tree_command ($$$@) {
	my $self = shift;
	my $tree = shift;
	my $command = shift;

	my $connection = $self->find_connection_by_tree($tree) || return;

	if ($command eq 'chdir') {
		my $dir = shift // '';

		$tree->cwd(_normalize_path($dir, $tree->cwd));
	} elsif ($command eq 'find') {
		my $pattern = _normalize_path(shift || "*", $tree->cwd, 1);
		my $dirname = $pattern =~ /^(.*)\\(.*)/ ? $1 : "";
		$pattern = $2 if $2;

		my $response = $self->process_request($connection, 'Create',
			file_name => $dirname,
			file_attributes => SMB::File::ATTR_DIRECTORY,
		);
		return unless $response && $response->is_success;
		my $fid = $response->fid;
		$response = $self->process_request($connection, 'QueryDirectory',
			file_pattern => $pattern,
			fid => $fid,
		);
		my $files = $response && $response->is_success ? $response->files : undef;
		$self->process_request($connection, 'Close',
			fid => $fid,
		);

		return wantarray ? @$files : $files;
	} elsif ($command eq 'dnload') {
		my $filename = shift // '';
		return $self->err("No filename") if $filename eq '';
		$filename = _normalize_path($filename, $tree->cwd, 1);
		my $dst_filename = _normalize_path(shift || _basename($filename, 1), '.');

		my $response = $self->process_request($connection, 'Create',
			file_name => $filename,
		);
		return unless $response && $response->is_success;
		my $file = $response->openfile->file;
		my $fid = $response->fid;
		my $remaining = $file->end_of_file;
		my $time = $file->mtime;
		my $content = '';
		my $offset = 0;
		while ($remaining) {
			my $length = $remaining >= 65536 ? 65536 : $remaining;
			$remaining -= $length;
			$response = $self->process_request($connection, 'Read',
				fid => $fid,
				offset => $offset,
				length => $length,
				remaining_bytes => $remaining,
			);
			return unless $response && $response->is_success;
			my $read = $response->length;
			return $self->err("Unexpected $read bytes read instead of $length at offset $offset")
				if $read != $length;
			$content .= $response->buffer;
			$offset += $length;
		}
		$self->process_request($connection, 'Close',
			fid => $fid,
		);

		open DST, '>', $dst_filename
			or return $self->err("Can't open $dst_filename for write: $!");
		print DST $content
			or return $self->err("Can't write content to $dst_filename: $!");
		close DST
			or return $self->err("Can't close $dst_filename after write: $!");

		# consider to set $time on file
		return 1;
	} elsif ($command eq 'upload') {
		my $filename = shift // '';
		return $self->err("No filename") if $filename eq '';
		$filename = _normalize_path($filename, '.');
		my $dst_filename = _normalize_path(shift || _basename($filename), $tree->cwd, 1);

		local $/ = undef;
		open SRC, '<', $filename
			or return $self->err("Can't open $filename for read: $!");
		my $content = <SRC>
			// return $self->err("Can't read content from $filename: $!");
		close SRC
			or return $self->err("Can't close $filename after read: $!");

		my $response = $self->process_request($connection, 'Create',
			file_name => $dst_filename,
			options => SMB::v2::Command::Create::OPTIONS_NON_DIRECTORY_FILE,
			access_mask => 0x12019f,
			disposition => SMB::File::DISPOSITION_OVERWRITE_IF,
		);
		return unless $response && $response->is_success;
		my $fid = $response->fid;
		my $remaining = length($content);
		my $offset = 0;
		while ($remaining) {
			my $length = $remaining >= 65536 ? 65536 : $remaining;
			$remaining -= $length;
			$response = $self->process_request($connection, 'Write',
				fid => $fid,
				offset => $offset,
				remaining_bytes => $remaining,
				buffer => substr($content, $offset, $length),
			);
			return unless $response && $response->is_success;
			my $written = $response->length;
			return $self->err("Unexpected $written bytes written instead of $length at offset $offset")
				if $written != $length;
			$offset += $length;
		}
		$self->process_request($connection, 'Close',
			fid => $fid,
		);

		return 1;
	} elsif ($command eq 'remove') {
		my $filename = shift // '';
		return $self->err("No filename") if $filename eq '';
		$filename = _normalize_path($filename, $tree->cwd, 1);

		my $is_dir = shift || 0;
		my $options = ($is_dir
			? SMB::v2::Command::Create::OPTIONS_DIRECTORY_FILE
			: SMB::v2::Command::Create::OPTIONS_NON_DIRECTORY_FILE
		) | SMB::v2::Command::Create::OPTIONS_DELETE_ON_CLOSE;
		my $response = $self->process_request($connection, 'Create',
			file_name => $filename,
			options => $options,
			access_mask => 0x10081,
		);
		return unless $response && $response->is_success;
		my $fid = $response->fid;
		$self->process_request($connection, 'Close',
			fid => $fid,
		);
		return unless $response && $response->is_success;

		return 1;
	}

	return;
}

sub on_response ($$$$) {
	my $self = shift;
	my $connection = shift;
	my $response = shift;
	my $request = shift;

	return 0;
}

sub wait_for_response ($$) {
	my $self = shift;
	my $connection = shift;
	my $request = $connection->sent_request;

	return unless $request;

	my $response = $connection->recv_command;
	if (!$response) {
		$self->delete_connection($connection);
		return;
	}

	unless ($response->is_response_to($request)) {
		$self->err("Unexpected: " . $response->dump);
		return;
	}

	return $response;
}

1;
