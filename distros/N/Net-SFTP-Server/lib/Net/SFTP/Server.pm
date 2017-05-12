package Net::SFTP::Server;

$VERSION = '0.03';

use strict;
use warnings;
use Carp;

use Fcntl qw(O_NONBLOCK F_SETFL F_GETFL);
use Errno ();
use Scalar::Util qw(dualvar);

use Net::SFTP::Server::Constants qw(:all);
use Net::SFTP::Server::Buffer;
our @CARP_NOT = qw(Net::SFTP::Server::Buffer);

our $debug;

sub _debug {
    local $\;
    print STDERR ((($debug & 256) ? "Server#$$#" : "#"), @_,"\n");
}

sub _debugf {
    my $fmt = shift;
    _debug sprintf($fmt, @_);
}

sub _hexdump {
    no warnings qw(uninitialized);
    my $data = shift;
    while ($data =~ /(.{1,32})/smg) {
        my $line=$1;
        my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
                (("  ") x 32))[0..31];
        $line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
	local $\;
        print STDERR join(" ", @c, '|', $line), "\n";
    }
}

sub set_error {
    my $self = shift;
    my $error = shift;
    if ($error) {
	my $str = (@_ ? join('', @_) : "Unknown error $error");
	$debug and $debug & 64 and _debug("error: $error, $str");
	$self->{error} = dualvar($error, $str);
    }
    else {
	$self->{error} = 0
    }
}

sub error { shift->{error} }

sub set_exit {
    my $self = shift;
    my $exit = shift;
    $self->{exit} = $exit;
}

sub set_error_and_exit {
    my $self = shift;
    my $code = shift;
    $self->set_exit(!!$code);
    $self->set_error($code, @_);
}

sub _prepare_fh {
    my ($name, $fh) = @_;
    $fh ||= do {
	no strict 'refs';
	\*{uc "STD$name"};
    };
    fileno $fh < 0 and croak "${name}_fh is not a valid file handle";
    my $flags = fcntl($fh, F_GETFL, 0);
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
    $fh;
}

sub new {
    @_ & 1 or croak 'Usage: $class->new(%opts)';
    my ($class, %opts) = @_;

    my $in_fh = _prepare_fh(in => delete $opts{in_fh});
    my $out_fh = _prepare_fh(out => delete $opts{out_fh});

    my $timeout = delete $opts{timeout};

    my $self = { protocol_version => 0,
		 in_fh => $in_fh,
		 out_fh => $out_fh,
		 in_buffer => '',
		 out_buffer => '',
		 in_buffer_max_size => 65 * 1024,
		 max_packet_size => 64 * 1024,
		 packet_handler_cache => [],
		 command_handler_cache => [],
		 timeout => $timeout,
	       };

    bless $self, $class;

    $self->set_error_and_exit;

    return $self;
}

sub set_protocol_version {
    my ($self, $version) = @_;
    $self->{packet_handler_cache} = [];
    $self->{command_handler_cache} = [];
    $self->{protocol_version} = $version;
}

sub _do_io_unix {
    my ($self, $wait_for_packet) = @_;

    my $out_b = \$self->{out_buffer};
    my $out_fh = $self->{out_fh};
    my $out_fn = fileno $out_fh;
    my $in_b = \$self->{in_buffer};
    my $in_fh = $self->{in_fh};
    my $in_fn = fileno $in_fh;
    my $in_buffer_max_size = $self->{in_buffer_max_size};
    my $timeout = $self->{timeout};
    my $packet_len;
    my $in_fh_closed;

    local $SIG{PIPE} = 'IGNORE';

    $debug and $debug & 32 and
	_debugf("_do_io_unix enter buffer_in: %d, buffer_out: %d",
		length $$in_b, length $$out_b);

    while (1) {
	if (!defined $packet_len and length $$in_b >= 4) {
	    $packet_len = unpack(N => $$in_b) + 4;
	    $debug and $debug & 32 and _debug "_do_io_unix packet_len: $packet_len";

	    if ($packet_len > $in_buffer_max_size) {
		$self->set_error_and_exit(1, "Packet of length $packet_len is too big");
		return undef;
	    }
	}

	if (defined $packet_len and $wait_for_packet) {
	    $wait_for_packet = ($packet_len > length $$in_b and
				!$in_fh_closed);
	    $debug and $debug & 32 and _debug "wait_for_packet set to $wait_for_packet";
	}

	$debug and $debug & 32 and
	    _debugf("_do_io_unix wait_for_packet: %d, packet_len: %s, in buffer: %d, out buffer: %d",
		    $wait_for_packet,
		    ($packet_len // 'undef'),
		    length($$in_b), length($$out_b));

	last unless ($wait_for_packet or length $$out_b);

	my $rb = '';
	length $$in_b < $in_buffer_max_size
	    and !$in_fh_closed
		and vec($rb, $in_fn, 1) = 1;

	my $wb = '';
	vec($wb, $out_fn, 1) = 1 if length $$out_b;

	$rb eq '' and $wb eq '' and croak "Internal error: useless select";

	my $n = select($rb, $wb, undef, $timeout);
	$debug and $debug & 32 and _debug "_do_io_unix select n: $n";
	if ($n >= 0) {
	    if (vec($wb, $out_fn, 1)) {
		my $bytes = syswrite($out_fh, $$out_b);
		if ($debug and $debug & 32) {
		    _debugf("_do_io_unix write queue: %s, syswrite: %s",
			    length $$out_b,
			    ($bytes // 'undef'));
		    $debug & 2048 and $bytes and _hexdump(substr($$out_b, 0, $bytes));
		}
		if ($bytes) {
		    substr($$out_b, 0, $bytes, '');
		}
		else {
		    $self->set_error_and_exit(1, "Broken connection");
		    return undef;
		}
	    }
	    if (vec($rb, $in_fn, 1)) {
		my $bytes = sysread($in_fh, $$in_b, 16*1024, length $$in_b);
		if ($debug and $debug & 32) {
		    _debugf("_do_io_unix sysread: %s, total read: %d",
			    ($bytes // 'undef'),
			    length $$in_b);
		    $debug & 1024 and $bytes and _hexdump(substr($$in_b, -$bytes));
		}
		unless ($bytes) {
		    $self->set_error_and_exit(1, "Connection closed by remote peer");
		    $in_fh_closed = 1;
		    undef $wait_for_packet;
		}
	    }
	}
	else {
	    next if ($n < 0 and $! == Errno::EINTR());
	    $debug and $debug & 32
		and _debugf("_do_io_unix failed, wait_for_packet: %d, packet_len: %s, in buffer: %d, out buffer: %d, n: %d, \$!: %s (%d)",
			    $wait_for_packet, ($packet_len // 'undef'), length($$in_b), length($$out_b), $n, $!, int $!);
	    return undef;
	}
    }
    $debug and $debug & 32
	and _debugf("_do_io_unix done, wait_for_packet: %d, packet_len: %s, in buffer: %d, out buffer: %d",
		    $wait_for_packet, ($packet_len // 'undef'), length($$in_b), length($$out_b));

    return !$in_fh_closed;
}

*_do_io = \&_do_io_unix;

sub get_packet {
    my $self = shift;
    my $in_b = \$self->{in_buffer};
    my $in_b_len = length $$in_b;
    $debug and $debug & 1 and
	_debugf("shift packet, in buffer len: %d, peeked packet len: %s",
		       $in_b_len,
		       ($in_b_len >= 4 ? unpack N => $$in_b : '-'));

    $in_b_len >= 4 or return undef;
    my $pkt_len = (unpack N => $$in_b);
    $in_b_len >= 4 + $pkt_len or return undef;
    $debug and $debug & 1 and _debug("got it!");
    substr($$in_b, 0, 4, '');
    substr($$in_b, 0, $pkt_len, '');
}

my %packer = ( uint8 => \&buf_push_uint8,
	       uint32 => \&buf_push_uint32,
	       uint64 => sub { croak "uint64 packing unimplemented" },
	       str => \&buf_push_str,
	       utf8 => \&buf_push_utf8,
	       name => \&buf_push_name,
	       attrs => \&buf_push_attrs,
	       raw => \&buf_push_raw);

sub push_packet {
    my $self = shift;
    my $out_b = \$self->{out_buffer};
    if (length $$out_b) {
	$self->set_error_and_exit(1,
	    "Internal error, packet already in output buffer");
	return undef;
    }

    if (@_ == 1) {
	buf_push_str($$out_b, $_[0]);
    }
    else {
	@_ & 1 and croak 'Usage: $sftp_server->push_packet(type => data, type => data, ...) or $sftp_server->push_packet($load)';
	$$out_b = "\x00\x00\x00\x00";
	while (@_) {
	    my $type = shift;
	    my $packer = $packer{$type};
	    if (defined $packer) {
		$packer->($$out_b, $_[0]);
		shift;
	    }
	    else {
		$self->set_error_and_exit(1,
                    "Internal error, invalid packing type $type");
		return;
	    }
	}
	substr $$out_b, 0, 4, pack(N => (length($$out_b) - 4));
    }
    if ($debug and $debug & 1) {
	_debugf "push_packet packet len %d", length $$out_b;
	$debug & 8 and _hexdump $$out_b;
    }

    1;
}

my %command_id = (init => 1,
		  open => 3,
		  close => 4,
		  read => 5,
		  write => 6,
		  lstat => 7,
		  fstat => 8,
		  setstat => 9,
		  fsetstat => 10,
		  opendir => 11,
		  readdir => 12,
		  remove => 13,
		  mkdir => 14,
		  rmdir => 15,
		  realpath => 16,
		  stat => 17,
		  rename => 18,
		  readlink => 19,
		  symlink => 20,
		  link => 21,
		  block => 22,
		  unblock => 23,
		  extended => 200);

my %response_id = (version => 2,
		   status => 101,
		   handle => 102,
		   data => 103,
		   name => 104,
		   attrs => 105,
		   extended => 201);

my @command_name;
while (my ($k, $v) = each %command_id) {
    $command_name[$v] = $k;
}

sub command_name { $command_name[$_[1]] }

sub response_id { $response_id{$_[1]} }

sub dispatch_packet {
    my $self = shift;
    my ($cmd) = buf_shift_uint8($_[0])
	or return $self->bad_packet();
    my ($id) = ($cmd == 1 ? undef : buf_shift_uint32 $_[0])
	or return $self->bad_packet($cmd);

    $debug and $debug & 1
	and _debugf("dispatch packet cmd %s, id: %s", $cmd, ($id // '-'));

    my $sub = $self->{_packet_handler_cache}[$cmd] ||= do {
	my $name = $self->command_name($cmd) || 'unknown';
	$self->can("handle_packet_${name}_v$self->{protocol_version}") ||
	    $self->can("handle_packet_${name}") ||
		$self->can('unsupported_command');
    };
    $debug and $debug & 4096 and _debug "packet handler: $sub";
    $sub->($self, $cmd, $id, $_[0]);
}

my @status_messages = ( "ok",
			"eof",
			"no such file",
			"permission denied",
			"failure",
			"bad message",
			"no connection",
			"connection lost",
			"operation not supported" );

sub push_status_response {
    my ($self, $id, $status, $msg, $lang) = @_;
    $msg //= ($status_messages[$status] // "failure");
    $lang //= 'en';
    $debug and $debug & 2 and _debug "push id: $id, status: $status, msg: $msg, lang: $lang";
    $self->push_packet(uint8 => SSH_FXP_STATUS,
		       uint32 => $id, uint32 => $status,
		       utf8 => $msg, str => $lang);
}

sub push_status_ok_response {
    my ($self, $id) = @_;
    $self->push_status_response($id, SSH_FX_OK)
}

sub push_status_eof_response {
    my ($self, $id) = @_;
    $self->push_status_response($id, SSH_FX_EOF)
}

sub push_handle_response {
    my ($self, $id, $hid) = @_;
    $debug and $debug & 2 and _debug "push handle hid: $hid";
    $self->push_packet(uint8 => SSH_FXP_HANDLE, uint32 => $id, str => $hid);
}

sub push_name_response {
    my $self = shift;
    my $id = shift;
    my $count = @_;
    $self->push_packet(uint8 => SSH_FXP_NAME,
		       uint32 => $id, uint32 => $count,
		       map { (name => $_) } @_);
}

sub push_attrs_response {
    my ($self, $id, $attrs) = @_;
    $self->push_packet(uint8 => SSH_FXP_ATTRS,
		       uint32 => $id, attrs => $attrs);
}

sub unsupported_command {
    my ($self, $cmd, $id) = @_;
    my $name = (uc $self->command_name($cmd) || $cmd);
    $debug and $debug & 2
	and _debugf("unsupported command %s [%d], id: %s",
		    $name, $cmd, ($id // '-'));
    $self->push_status_response($id, SSH_FX_OP_UNSUPPORTED,
			      "command $name is not supported");
}

sub run {
    my $self = shift;
    until ($self->{exit}) {
	$self->_do_io(1) or next;
	my $pkt = $self->get_packet;
	$self->dispatch_packet($pkt) if defined $pkt;
    }
    $self->{exit};
}

sub bad_packet {
    my ($self, $cmd, $id) = @_;
    $cmd //= 'undef';
    $id //= 'id';
    $self->set_error_and_exit(1, "Invalid packet cmd: $cmd, id: $id");
}

sub bad_command {
    my ($self, $cmd, $id, $msg) = @_;
    my $str = "Bad message";
    $str .= ": $msg" if defined $msg;
    $self->push_status_response($id, SSH_FX_BAD_MESSAGE, $str);
}

sub dispatch_command {
    my $self = shift;
    my $cmd = shift;

    $debug and $debug & 2
	and _debugf("dispatch command cmd %d %s, id: %s",
		    $cmd,
		    ($self->command_name($cmd) // '-'),
		    ($_[0] // '-'));

    my $sub = $self->{_command_handler_cache}[$cmd] ||= do {
	my $name = $self->command_name($cmd) || 'unknown';
	$self->can("handle_command_${name}_v$self->{protocol_version}") ||
	    $self->can("handle_command_${name}") ||
		sub { shift->unsupported_command($cmd, $_[0]) };
    };
    $sub->($self, @_);
}

sub handle_packet_init_v0 {
    my ($self, $cmd) = @_;
    my $version = buf_shift_uint32($_[3]) // goto BAD_PACKET;
    my @ext;
    while (length $_[3]) {
	push (@ext,
	      (buf_shift_str($_[3]) // goto BAD_PACKET),
	      (buf_shift_str($_[3]) // goto BAD_PACKET));
    }
    return $self->dispatch_command($cmd, undef, $version, @ext);

 BAD_PACKET:
    return $self->bad_packet($cmd);
}

sub handle_command_init_v0 {
    my $self = shift;
    shift; # $id
    my $version = shift;
    $version >= 3 or return $self->bad_packet(1);
    $self->set_protocol_version(3);
    $self->push_packet(uint8 => SSH_FXP_VERSION, uint32 => 3,
		       map { (str => $_) } $self->server_extensions);
}

sub server_extensions {
    return ('libnet-sftp-server@cpan.org' => 1);
}

sub _make_packet_handler {
    my $name = shift;
    my @args = map "\n        (buf_shift_$_(\$_[3]) // goto BAD_PACKET)", @_;
    my $args = join(",", @args);
    my $code = <<EOC; 
sub {
    my (\$self, \$cmd, \$id) = \@_;
    \$debug and \$debug & 2 and _debug "$name unpacker called";
    return \$self->dispatch_command(\$cmd, \$id,$args);
  BAD_PACKET:
    \$self->bad_command(\$cmd, \$id, 'missing parameter')
}
EOC
    $debug and $debug & 16384 and _debug "$name packet handler code:\n$code";
    my $method = "handle_packet_$name";
    no strict 'refs';
    *$method = eval $code;
}

_make_packet_handler open_v3 => qw(utf8 uint32 attrs);
_make_packet_handler close_v3 => qw(str);
_make_packet_handler read_v3 => qw(str uint64 uint32);
_make_packet_handler write_v3 => qw(str uint64 str);
_make_packet_handler stat_v3 => qw(utf8);
_make_packet_handler lstat_v3 => qw(utf8);
_make_packet_handler fstat_v3 => qw(str);
_make_packet_handler setstat_v3 => qw(utf8 attrs);
_make_packet_handler fsetstat_v3 => qw(str attrs);
_make_packet_handler opendir_v3 => qw(utf8);
_make_packet_handler readdir_v3 => qw(str);
_make_packet_handler remove_v3 => qw(utf8);
_make_packet_handler mkdir_v3 => qw(utf8 attrs);
_make_packet_handler rmdir_v3 => qw(utf8);
_make_packet_handler realpath_v3 => qw(utf8);
_make_packet_handler rename_v3 => qw(utf8 utf8);
_make_packet_handler readlink_v3 => qw(utf8);
_make_packet_handler symlink_v3 => qw(utf8 utf8 utf8);

1;
__END__

=head1 NAME

Net::SFTP::Server - Base class for writting SFTP servers

=head1 SYNOPSIS

  use parent qw(Net::SFTP::Server);
  ...

=head1 DESCRIPTION

This package provides a framework for implementing SFTP servers.

This is an early release without documentation. The API is very
unstable yet.

Currently version 3 of the protocol as defined in
L<http://www.openssh.org/txt/draft-ietf-secsh-filexfer-02.txt> is
supported, thought there are provisions for supporting later versions.

For and example of usage, see the source code for the companion module
L<Net::SFTP::Server::FS> and the script L<sftp-server-fs-perl>
implementing an standard SFTP server.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
