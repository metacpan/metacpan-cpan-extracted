package Net::FSP;
use 5.006;
use strict;
use warnings;
our $VERSION = 0.16;

use Carp qw/croak/;
use Socket qw/PF_INET SOCK_DGRAM sockaddr_in inet_aton INADDR_ANY/;
use Errno qw/EAGAIN ENOBUFS EHOSTUNREACH ECONNREFUSED EHOSTDOWN ENETDOWN EPIPE EINTR/;
use Fcntl qw/F_GETFL F_SETFL O_NONBLOCK/;
use Symbol qw/gensym/;

use Net::FSP::File;
use Net::FSP::Dir;
use Net::FSP::Handle;

my $HEADER_SIZE         = 12;
my $LISTING_HEADER_SIZE = 9;
my $LISTING_ALIGNMENT   = 4;
my $SIXTEEN_BITS        = 0xFFFF;
my $DEFAULT_MAX_SIZE    = 1024;
my $NO_POS              = 0;

my %code_for = (
	version   => 0x10,
	info      => 0x11,    #future
	'err'     => 0x40,
	get_dir   => 0x41,
	get_file  => 0x42,
	put_file  => 0x43,
	install   => 0x44,
	del_file  => 0x45,
	del_dir   => 0x46,
	get_pro   => 0x47,
	set_pro   => 0x48,
	make_dir  => 0x49,
	say_bye   => 0x4A,
	grab_file => 0x4B,
	grab_done => 0x4C,
	stat_file => 0x4D,
	move_file => 0x4E,
	ch_passw  => 0x4F,    #future
);
my %type_of = (
	0x00 => 'end',
	0x01 => 'file',
	0x02 => 'dir',
	0x2A => 'skip',
);

my %pos_must_match_for = map { $code_for{$_} => 1 } qw/info get_dir get_file put_file grab_file/;

my @info = qw/logging read-only reverse-lookup private-mode throughput-control extra-data/;
my @mods = qw/owner delete create mkdir private readme list rename/;

my %is_nonfatal = map { $_ => 1 } (ENOBUFS, EHOSTUNREACH, ECONNREFUSED, EHOSTDOWN, ENETDOWN, EPIPE, EAGAIN, EINTR);

my %connect_sub_for = (
	ipv4 => \&_connect_ipv4,
	ipv6 => \&_connect_ipv6,
);

my %dispatch_for = (
	file => 'Net::FSP::File',
	dir  => 'Net::FSP::Dir',
);

my %default_options = (
	remote_port      => 21,
	local_port       => 0,
	local_adress     => undef,
	min_delay        => 1.34,
	max_delay        => 60,
	delay_factor     => 1.5,
	max_payload_size => $DEFAULT_MAX_SIZE,
	password         => undef,
	key              => 0,
	network_layer    => 'ipv4',
	current_dir      => '/',
);

# Constructor and helper functions
sub new {
	my ($class, $remote_host, $options) = @_;
	croak 'Hostname undefined' if not defined $remote_host;
	$options ||= {};
	my %self = (
		%default_options,
		%{$options},
		remote_host => $remote_host,
		message_id  => int rand 65_536,
		rin         => '',
	);
	for my $size (qw/read_size write_size listing_size/) {
		$self{$size} ||= $self{max_payload_size};
	}
	my $self = bless \%self, $class;
	my $connector = $connect_sub_for{ $self->{network_layer} } or croak 'No such network layer';
	$self->$connector();
	$self->_prepare_socket();
	$self->change_dir($self->{current_dir});
	return $self;
}

sub _connect_ipv4 {
	my $self = shift;

	socket $self->{socket}, PF_INET, SOCK_DGRAM, 0 or croak "Could not make socket: $!";
	my $local_address = $self->{local_address} ? inet_aton($self->{local_address}) : INADDR_ANY or croak "No such localhost: $!";
	bind $self->{socket}, sockaddr_in($self->{local_port}, $local_address) or croak "Could not bind: $!";
	my $packed_ip = inet_aton($self->{remote_host}) or croak "No such host '$self->{remote_host}'";
	connect $self->{socket}, sockaddr_in($self->{remote_port}, $packed_ip) or croak "Could not connect to remote host: $!";
	return;
}

sub _connect_ipv6 {
	my $self = shift;
	require Socket6;

	my $family = Socket6::PF_INET6();
	socket $self->{socket}, $family, SOCK_DGRAM, 0 or croak "Could not make socket: $!";
	my $local_ip = $self->{local_address} ? Socket6::inet_pton($family, $self->{local_address}) || croak "No such localhost: $!" : Socket6::in6addr_any();
	bind $self->{socket}, Socket6::pack_sockaddr_in6($self->{local_port}, $local_ip) or croak "Could not bind: $!";
	my $packed_ip = Socket6::gethostbyname2($self->{remote_host}, $family) or croak "No such host '$self->{remote_host}'";
	connect $self->{socket}, Socket6::pack_sockaddr_in6($self->{remote_port}, $packed_ip) or croak "Could not connect to remote host: $!";
	return;
}

sub _prepare_socket {
	my $self = shift;
	binmode $self->{socket}, ':raw';
	my $flags = fcntl $self->{socket}, F_GETFL, 0 or croak "Can't get flags for the socket: $!";
	fcntl $self->{socket}, F_SETFL, $flags | O_NONBLOCK or croak "Can't set flags for the socket: $!";
	vec($self->{rin}, fileno $self->{socket}, 1) = 1;
	return;
}

# send_receive and helpers

sub _checksum {
	my ($package, $sum) = @_;
	$sum += unpack '%32a*', $package;
	return ($sum + ($sum >> 8)) & 0xFF;
}

sub _pack_request {
	my ($self, $send_command, $send_pos, $send_data, $send_extra) = @_;
	$self->{message_id} = $self->{message_id} + 1 & $SIXTEEN_BITS;
	my $request = pack 'CxnnnN a*a*', $code_for{$send_command}, $self->{key}, $self->{message_id}, length $send_data, $send_pos, $send_data, $send_extra;
	vec($request, 1, 8) = _checksum($request, length $request);
	return $request;
}

sub _check_fatal {
	my $message = shift;
	croak "$message: $!" if not $is_nonfatal{ $! + 0 };
	return;
}

sub _receive {
	my ($self, $response) = @_;
	return defined recv $self->{socket}, ${$response}, $self->{max_payload_size} + $HEADER_SIZE, 0 or _check_fatal('Could not receive');
}

sub _send {
	my ($self, $request) = @_;
	send $self->{socket}, $request, 0 or _check_fatal('Could not send');
	return;
}

sub _replies_pending {
	my $self = shift;
	my $delay = shift || 0;
	return scalar select my $rout = $self->{rin}, undef, undef, $delay;
}

sub _unpack_response {
	my ($self, $response) = @_;
	my %fields;
	@fields{ 'command', 'checksum', 'key', 'message_id', 'length', 'pos', 'fulldata' } = unpack 'CCnnnN a*', $response;
	@fields{ 'data', 'extra' } = unpack "a[$fields{length}]a*", $fields{fulldata};
	return %fields;
}

sub _response_is_correct {
	my ($self, $value_for, $response, $send_command, $send_pos) = @_;
	vec($response, 1, 8) = 0;
	return
	      $value_for->{checksum} == _checksum($response, 0)
	  and length $value_for->{fulldata} >= $value_for->{length}
	  and ($value_for->{command} == $code_for{$send_command} || $value_for->{command} == $code_for{err})
	  and not($pos_must_match_for{ $value_for->{command} } && $send_pos != $value_for->{pos});
}

# the main networking function, known as interact() in the C library.
sub _send_receive {
	my ($self, $send_command, $send_pos, $send_data, $send_extra) = @_;
	$send_extra = '' if not defined $send_extra;

	my $request = $self->_pack_request($send_command, $send_pos, $send_data, $send_extra);
	ATTEMPT:
	for (my $delay = $self->{min_delay} ; $delay < $self->{max_delay} ; $delay *= $self->{delay_factor}) {
		if (not $self->_replies_pending) {
			$self->_send($request);
			next ATTEMPT if not $self->_replies_pending($delay);
		}
		next ATTEMPT if not $self->_receive(\my $response);
		next ATTEMPT if length $response < $HEADER_SIZE;
		my %response = $self->_unpack_response($response);
		next ATTEMPT if not $self->_response_is_correct(\%response, $response, $send_command, $send_pos);
		$self->{key} = $response{key};
		redo ATTEMPT if $response{message_id} != $self->{message_id};

		croak sprintf 'Received error from server: %s', unpack 'Z*', $response{data} if $response{command} == $code_for{err};
		return wantarray ? @response{ 'data', 'extra' } : $response{data};
	}
	croak 'Remote server not responding';
}

#the rest...

sub _make_remote {
	my ($self, $name) = @_;
	my @current = $name =~ m{ \A / }xms ? () : split m{ / }x, $self->{current_dir};
	my @future = grep { !/ \A \.? \z /xms } split m{ / }x, $name;
	for my $step (@future) {
		if ($step eq '..') {
			croak 'Can\'t go outside of root directory' if @current == 0;
			pop @current;
		}
		else {
			push @current, $step;
		}
	}
	return join '/', @current;
}

sub _convert_filename {
	my ($self, $filename, $escaped) = @_;
	my $path = defined $escaped ? $filename : $self->_make_remote($filename);
	return sprintf "%s%s\0", $path, defined $self->{password} ? "\n" . $self->{password} : '';
}

sub _connected {
	my $self = shift;
	return $self->{key} != 0;
}

sub DESTROY {
	my $self = shift;
	$self->say_bye if $self->_connected;
	close $self->{socket} or croak "Couldn't close socket?!: $!";
	return;
}

sub current_dir {
	my $self = shift;
	return $self->{current_dir};
}

sub change_dir {
	my ($self, $newdir) = @_;
	$newdir = $self->_make_remote($newdir);
	$self->_send_receive('get_pro', $NO_POS, $self->_convert_filename($newdir, 1));
	my $olddir = $self->{current_dir};
	$self->{current_dir} = Net::FSP::Dir->new($self, $self->{current_dir}, %{ $self->stat_file($newdir, 1) });
	return $olddir;
}

sub say_bye {
	my $self = shift;
	$self->_send_receive('say_bye', $NO_POS, '');
	$self->{key} = 0;
	return;
}

sub server_version {
	my $self = shift;
	my $version = unpack 'Z*', scalar $self->_send_receive('version', $NO_POS, '');
	chomp $version;
	return $version;
}

sub server_config {
	my $self = shift;
	my (undef, $extra) = $self->_send_receive('version', $NO_POS, '');
	my @extra = unpack 'b5', $extra;
	my %prot = map { $info[$_] => $extra[$_] } 0..$#info;
	return \%prot;
}

sub cat_file {
	my ($self, $filename) = @_;
	my $return_value = '';
	$self->download_file($filename, sub { $return_value .= $_[0] });
	return $return_value;
}

sub _get_reader {
	my ($self, $code, $filename, $pos_ref) = @_;
	my $remote_name = $self->_convert_filename($filename);
	my $extra = $self->{read_size} != $DEFAULT_MAX_SIZE ? pack 'n', $self->{read_size} : '';
	return sub {
		my $block = $self->_send_receive($code, ${$pos_ref}, $remote_name, $extra);
		${$pos_ref} += length $block;
		return $block;
	};
}

sub _download_to {
	my ($self, $code, $filename, $add) = @_;
	my $pos = 0;
	my $reader = $self->_get_reader($code, $filename, \$pos);
	BLOCK:
	while (1) {
		my $block = $reader->();
		last BLOCK if length $block == 0;
		$add->($block);
	}
	return;
}

sub download_file {
	my ($self, $filename, $other) = @_;
	if (ref($other) eq '') {
		open my $fh, '>:raw', $other or croak "Couldn't open file '$other' for writing: $!";
		$self->download_file($filename, $fh);
		close $fh or croak "Couldn't close filehandle: $!";
	}
	elsif (ref($other) eq 'GLOB') {
		$self->_download_to('get_file', $filename, sub { print {$other} @_ or croak "Couldn't write: $!" });
	}
	else {
		$self->_download_to('get_file', $filename, $other);
	}
	return;
}

sub grab_file {
	my ($self, $filename, $other) = @_;
	if (ref($other) eq '') {
		open my $fh, '>:raw', $other or croak "Couldn't open file '$other' for writing: $!";
		$self->grab_file($filename, $fh);
		close $fh or croak "Couldn't close filehandle: $!";
	}
	elsif (ref($other) eq 'GLOB') {
		$self->_download_to('grab_file', $filename, sub { print {$other} @_ or croak "Couldn't write: $!" });
	}
	else {
		$self->_download_to('grab_file', $filename, $other);
	}
	$self->_send_receive('grab_done', $NO_POS, $self->_convert_filename($filename));
	return;
}

sub list_dir {
	my ($self, $raw_dir) = @_;
	my $remote_dir = $self->_make_remote($raw_dir);
	my $dirname = $self->_convert_filename($remote_dir, 1);

	my $extra = $self->{listing_size} != $DEFAULT_MAX_SIZE ? pack 'n', $self->{listing_size} : '';
	my ($data, $cursor, @entries) = ('', 0);

	ENTRY:
	while (1) {
		if (length($data) < $LISTING_HEADER_SIZE) {
			$data = $self->_send_receive('get_dir', $cursor++, $dirname, $extra);
		}

		my ($time, $size, $type_id) = unpack 'NNC', substr $data, 0, $LISTING_HEADER_SIZE, '';
		my $type = $type_of{$type_id};

		if ($type eq 'end') {
			last ENTRY;
		}
		elsif ($type eq 'file' or $type eq 'dir') {
			my ($filename) = $data =~ / \A ( [^\0]+ ) /xms or croak 'No filename present?!';
			my $padding = $LISTING_ALIGNMENT - (length($filename) + $LISTING_HEADER_SIZE) % $LISTING_ALIGNMENT;
			substr $data, 0, length($filename) + $padding, '';
			next ENTRY if $filename eq '.' or $filename eq '..';
			my ($link) = $filename =~ s/ \n ( [^\n]+ ) \z //xms;
			push @entries, $dispatch_for{$type}->new(
				$self,
				"$remote_dir/$filename",
				time => $time,
				size => $size,
				type => $type,
				(length $link ? (link => $link) : ()),
			);
		}
		elsif ($type eq 'skip') {
			$data = $self->_send_receive('get_dir', $cursor++, $dirname, $extra);
		}
	}
	return @entries;
}

sub stat_file {
	my ($self, $filename, $escaped) = @_;
	my ($time, $size, $type_id) = unpack 'NNC', $self->_send_receive('stat_file', $NO_POS, $self->_convert_filename($filename, $escaped));
	my $type = $type_of{$type_id};
	croak "No such file '$filename'" if $type eq 'end';
	if (wantarray) {
		return ($time, $size, $type);
	}
	else {
		return $dispatch_for{$type}->new($self, $filename, size => $size, type => $type, time => $time);
	}
}

sub _get_writer {
	my ($self, $filename, $timestamp, $handle) = @_;
	my $position = 0;
	croak 'You can only write one file at the same time' if $self->{writing};
	$self->{writing} = 1;
	return sub {
		my $part = shift;
		if (defined $part) {
			$self->_send_receive('put_file', $position, $part);
			$position += length $part;
			chomp $part;
		}
		else {
			$self->_send_receive('install', $NO_POS, $self->_convert_filename($filename), defined $timestamp ? pack('N', $timestamp) : '');
			$self->{writing} = 0;
		}
	};
}

sub _upload_to {
	my ($self, $filename, $sub, $timestamp) = @_;
	my $writer = $self->_get_writer($filename, $timestamp);
	while (1) {
		my $part = $sub->($self->{write_size});
		$writer->($part);
		last if not defined $part;
	}
	return;
}

sub upload_file {
	my ($self, $filename, $other, $timestamp) = @_;
	if (ref($other) eq '') {
		open my $fh, '<:raw', $other or croak "Couldn't open file '$other' for reading: $!";
		$self->upload_file($filename, $fh, $timestamp);
		close $fh or croak "Couldn't close filehandle!?: $!";
	}
	elsif (ref($other) eq 'GLOB') {
		$self->_upload_to(
			$filename,
			sub {
				defined read $other, my $return_value, $_[0] or croak "Couldn't read: $!";
				return length $return_value ? $return_value : undef;
			},
			$timestamp
		);
	}
	else {
		$self->_upload_to($filename, $other, $timestamp);
	}
	return;
}

sub remove_file {
	my ($self, $filename) = @_;
	$self->_send_receive('del_file', $NO_POS, $self->_convert_filename($filename));
	return;
}

sub remove_dir {
	my ($self, $filename) = @_;
	$self->_send_receive('del_dir', $NO_POS, $self->_convert_filename($filename));
	return;
}

sub _protection_helper {
	my ($self, $command, $filename, $extra) = @_;
	my $protection = ($self->_send_receive($command, $NO_POS, $self->_convert_filename($filename), $extra))[1];
	my @bits = split //x, unpack 'b8', $protection;
	my %prot = map { $mods[$_] => $bits[$_] } 0..$#mods;
	return \%prot;
}

sub get_readme {
	my ($self, $filename) = @_;
	return scalar $self->_send_receive('get_pro', $NO_POS, $self->_convert_filename($filename));
}

sub get_protection {
	my ($self, $filename) = @_;
	return $self->_protection_helper('get_pro', $self->_convert_filename($filename));
}

sub set_protection {
	my ($self, $filename, $mod) = @_;
	return $self->_protection_helper('set_pro', $filename, $mod);
}

sub make_dir {
	my ($self, $filename) = @_;
	$self->_send_receive('make_dir', $NO_POS, $self->_convert_filename($filename));
	return;
}

sub move_file {
	my ($self, $old_name, $new_name) = @_;
	$self->_send_receive('move_file', $NO_POS, $self->_convert_filename($old_name), $self->_convert_filename($new_name));
	return;
}

sub CLONE_SKIP {
	return 1;
}

sub open_file {
	my ($self, $filename, $mode) = @_;
	my $ret = gensym;
	tie *{$ret}, 'Net::FSP::Handle', $self, $filename, $mode or croak "Could not open remote file $filename: $!";
	return $ret;
}

1;

__END__

=head1 NAME

Net::FSP - A client implementation of the File Service Protocol

=head1 VERSION

This documentation refers to Net::FSP version 0.16

=head1 SYNOPSIS

 use Net::FSP;
 my $fsp = Net::FSP->new("hostname", { remote_port => 21 });
 
 $fsp->current_dir->download('./');  
 #do something
 $fsp->upload_file('foo', 'foo');

=head1 DESCRIPTION

FSP is a very lightweight UDP based protocol for transferring files. FSP has
many benefits over FTP, mainly for running anonymous archives. FSP protocol is
valuable in all kinds of environments because it is one of the few protocols
that is not aggressive about bandwidth while at the same time being
sufficiently fault tolerant. Net::FSP is a class implementing the client side of
FSP.

=head1 METHODS

=over 4

=item new($remote_host, {...})

Creates a new Net::FSP object. As its optional second argument it takes a
hashref of the following members:

=over 4

=item remote_port

The remote port to connect to. It defaults to B<21>.

=item local_address

The local address to bind to. This parameter is usually only needed on
multihomed connections. By default a socket isn't bound to a particular
interface.

=item local_port

The local port to bind the connection to. It defaults to B<0> (random).

=item min_delay

The minimal delay in seconds before a request is resent. It defaults to
B<1.34>.

=item delay_factor

The factor with which the delay increases each time a request goes
unresponded. It defaults to B<1.5>.

=item max_delay

The maximal delay for resending a request. If the delay would have been larger
than this an exception is thrown. It defaults to B<60> seconds.

=item password 

Your password for this server. It defaults to B<undef> (none).

=item max_payload_size

The maximal size of the payload. It defaults to B<1024>. Some servers may not
support values higher than 1024. Setting this higher than the MTU - 12 is
not recommended.

=item network_layer

This sets the protocol used as network layer. Currently the only supported
values are B<ipv4> (the default) and B<ipv6> (this requires having the Socket6
module installed). As of writing no FSP server supports ipv6 yet though.

=item read_size

The size with which data is requested from the server. It defaults to
I<max_payload_size>.

=item write_size

The size with which data is written to the server. It defaults to
I<max_payload_size>.

=item listing_size

The size with which directories are read from the server. It defaults to
I<max_payload_size>.

=back

=item current_dir()

This method returns the current working directory on the server.

=item change_dir($new_directory)

This method changes the current working directory on the server. It returns the
previous working directory.

=item say_bye()

This method releases the connection to the FSP server. Note that this doesn't
mean the connection is closed, it only means other clients from the same host
can now contact the server.

=item server_version()

This method returns the full version of the server.

=item server_config()

This method returns some information about the configuration of the server. It
returns a hashref with the following elements: I<logging>, I<read-only>,
I<reverse-lookup>, I<private-mode> I<throughput-control> I<extra-data>.

=item download_file($file_name, $sink)

This method downloads file C<$file_name> to C<$sink>. C<$sink> must either be an
untainted filename, a filehandle or a callback function.

=item cat_file($file_name)

This method downloads file C<$file_name> and returns it as a string. Using this
on large files is not recommended.

=item grab_file($file_name, $sink)

This method downloads file C<$file_name>, and deletes it at when this is done.
These actions are considered atomic by the server. Its arguments work as in
C<download_file>.

=item list_dir($directory_name)

This method returns a list of files and subdirectories of directory
C<$directory_name>. The entries in the lists are either a L<Net::FSP::File> or a
L<Net::FSP::Dir> for files and directories respectively.

=item stat_file($file_name)

In list context this returns a list of: the modification time (in unix format),
the size (in bytes), and the type (either I<'file'> or I<'dir'>) of file
C<$file_name>. In scalar context it returns either a L<Net::FSP::File> or a
L<Net::FSP::Dir> object for files and directories respectively.

=item upload_file($file_name, $source)

This method uploads file C<$file_name> to the server. C<$source> must either be
a filename, a filehandle or a callback function.

=item open_file($file_name, $mode)

Open a file and return a filehandle.

=item remove_file($file_name)

This method deletes file C<$file_name>.

=item remove_dir($directory_name)

This method deletes directory C<$directory_name>.

=item get_readme($dirname)

This method returns the readme for a directory, if there is any.

=item get_protection($directory_name)

This method returns the directory's protection. It returns a hash
reference with the elements C<owner>, C<delete>, C<create>, C<mkdir>,
C<private>, C<readme>, C<list> and C<rename>.

=item set_protection($directory_name, $mode)

This method changes the permission of directory C<$directory_name> for public
users. It's mode argument is consists of two characters. The first byte is I<+>
or I<->, to indicate whether the permission is granted or revoked. The second
byte contains a I<c>, I<d>, I<g>, I<m>, I<l> or I<r> for the permission to
create files, delete files, get files, create directories, list the directory
or rename files.  Its return value is the same as get_protection. 

=item make_dir($directory_name)

This method creates a directory named C<$directory_name>. 

=item move_file($old_name, $new_name)

This method moves C<$old_name> to C<$new_name>.

=back

=head1 DIAGNOSTICS

If the server encounters an error, it will be thrown as an exception string,
prepended by I<'Received error from server: '>. Unfortunately the content of
these errors are not well documented. Since the protocol is mostly stateless
one can usually assume these errors have no effect on later requests. If the
server doesn't respond at all, a 'Remote server not responding.' exception will
eventually be thrown.

=head1 DEPENDENCIES

This module depends on perl version 5.6 or higher.

=head1 BUGS AND LIMITATIONS

FSP connections can not be shared between threads. Other than that, there are no
known problems in this module.
Please report problems to Leon Timmermans (fawaka@gmail.com). Patches are welcome.

=head1 CONFIGURATION AND ENVIRONMENT

This module has no configuration file. All configuration is done through the
constructor. Some utility functions to make used of the environment are defined
in L<Net::FSP::Util>.

=head1 INCOMPATIBILITIES

This module has no known incompatibilities.

=head1 AUTHOR

Leon Timmermans, fawaka@gmail.com

=head1 SEE ALSO

The protocol is described at L<http://fsp.sourceforge.net/doc/PROTOCOL.txt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, 2008 Leon Timmermans. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.
