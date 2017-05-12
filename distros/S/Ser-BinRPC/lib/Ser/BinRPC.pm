# Ser::BinRPC.pm
#
# Copyright (c) 2010 Tomas Mandys <tomas.mandys@2p.cz>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. 

package Ser::BinRPC;

use strict;
#no strict "refs";

use warnings;
use Socket;
use IO::Socket;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ser::BinRPC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Ser::BinRPC', $VERSION);

my %data_type = (
	INT => 0,
	STR => 1,   # 0 term, for easier parsing 
	DOUBLE => 2,
	STRUCT => 3,	
	ARRAY => 4,
	AVP => 5,   # allowed only in structs 
	BYTES => 6  # like STR, but not 0 term
);

my %message_type = (
	REQ => 0,
	REPL => 1,
	FAULT => 3
);

my %sock_type_by_proto = (
	udp => SOCK_DGRAM,
	tcp => SOCK_STREAM
);

# ------------------------ module subroutines ------------------------

sub binrpc_get_int_len($) {
	my ($i) = @_;
	my $size;
	for ($size=4; $size && (($i & (0xff<<24))==0); $i<<=8, $size--) {};
	return $size;	
}

sub binrpc_write_int(\@$) {
	my ($arr, $i) = @_;
	my $size;
	for ($size=4; $size && (($i & (0xff<<24))==0); $i<<=8, $size--) {};
	my $n;
	for ($n=$size; $n; $n--){
		push(@$arr, (($i>>24) & 0xFF));
		$i<<=8;
	}
	return $size;
}

sub binrpc_read_int(\@$\$) {
	my ($arr, $len, $i) = @_;

	if ($len > scalar(@$arr)) {
		return 0;
	}
	$$i = 0;
	for (; $len>0; $len--) {
		$$i <<= 8;
		$$i |= shift(@$arr);		
	}
	return 1;
}

sub binrpc_add_str(\@$) {
	my ($arr, $s) = @_;

	my $l = length($s)+1;
	my $size;
	if ($l < 8) {	
		push(@$arr, ($l << 4) | $data_type{STR});
	}
	else {
		push(@$arr, (binrpc_get_int_len($l) << 4) | 0x80 | $data_type{STR});
		binrpc_write_int(@$arr, $l);
	}
	for my $i (0 .. length($s)-1) {
		push(@$arr, unpack('C', substr($s, $i, 1)));
	}
	push(@$arr, 0);
}

sub binrpc_add_int(\@$) {
	my ($arr, $x) = @_;
	push(@$arr, (binrpc_get_int_len($x) << 4) | $data_type{INT});
	binrpc_write_int(@$arr, $x);
}

sub binrpc_add_double(\@$) {
	my ($arr, $x) = @_;
	$x = int($x*1000);
	push(@$arr, binrpc_get_int_len($x) <<4 | $data_type{DOUBLE});
	binrpc_write_int(@$arr, $x);
}

sub binrpc_read_record(\@$\$\$\$);  # forward declaration to introduce prototype for recursive usage

sub binrpc_read_record(\@$\$\$\$) {
	my ($arr, $nesting, $val_type, $val, $name) = @_;
	my $end_tag = 0;

	if (scalar(@$arr) == 0) {
		return 0;
	}
	my $len = shift(@$arr);
	if (defined $$val_type && (($len & 0x0F) != $$val_type)) {
		return 0;
	}
	$$val_type = $len & 0x0F;
	$len >>= 4;
	if ($len & 0x08) {
		$end_tag=1; # possible end mark for array or structs
		unless (binrpc_read_int(@$arr, $len & 0x07, $len)) { # we have to read len bytes and use them as the new len */
			return 0;
		}
	}
	if ($len > scalar(@$arr)) {
		return 0;
	}
	if ($nesting eq 'S') {
		if ($$val_type == $data_type{STRUCT} ) {
			if ($end_tag) {
				undef $$val_type;  # end of struct
				return 1;
			}
			else {
				return 0;
			}
		} elsif ($$val_type == $data_type{AVP} ) {
			$$name = '';
			for my $i (0 .. $len-2) {
				$$name .= pack('C', shift @$arr);				
			}
			shift @$arr;  # zero term
			if (scalar(@$arr) == 0) {
				return 0;
			}

			$$val_type = $$arr[0] & 0x0F;
			if ($$val_type == $data_type{AVP} || $$val_type == $data_type{ARRAY}) {
				return 0;
			}
			my ($dummy);
			unless (binrpc_read_record(@$arr, '', $$val_type, $$val, $dummy)) {
				return 0;
			}
			return 1;

		} else {
			return 0;
		}
	}
	else {
		if ($$val_type == $data_type{INT} ) {
			unless (binrpc_read_int(@$arr, $len, $$val)) { # we have to read len bytes and use them as the new len */
				return 0;
			}

		} elsif ($$val_type == $data_type{DOUBLE} ) {
			unless (binrpc_read_int(@$arr, $len, $$val)) { # we have to read len bytes and use them as the new len */
				return 0;
			}
			$$val = ($$val*1.00)/1000;

		} elsif ($$val_type == $data_type{STR} ) {
			$$val = '';
			for my $i (0 .. $len-2) {
				$$val .= pack('C', shift @$arr);				
			}
			shift @$arr; # zero term

		} elsif ($$val_type == $data_type{BYTES} ) {
			$$val = '';
			for my $i (0 .. $len-1) {
				$$val .= pack('C', shift @$arr);				
			}

		} elsif ($$val_type == $data_type{STRUCT} ) {
			if ($end_tag) {
				return 0;
			}
			my %s = ();
			my ($val_type2, $val2, $name2);
			do {
				undef $val_type2;
				unless (binrpc_read_record(@$arr, 'S', $val_type2, $val2, $name2)) {
					return 0;
				}
				if (defined $val_type2) {
					$s{$name2} = $val2;
				}
			} while (defined $val_type2);
			$$val = \%s;

		} elsif ($$val_type == $data_type{ARRAY} ) {
			if ($end_tag) {
				if ($nesting eq 'A') {
					undef $$val_type;
					return 1;
				} else {
					return 0;
				}
			}
			my @a2 = ();
			my ($val_type2, $val2, $name2);
			do {
				undef $val_type2;
				unless (binrpc_read_record(@$arr, 'A', $val_type2, $val2, $name2)) {
					return 0;
				}
				if (defined $val_type2) {
					push (@a2, $val2);
				}
			} while (defined $val_type2);
			$$val = \@a2;

		} else {
			return 0;
		}
	}
	return 1;
}

# ----------------------------- begin of object ------------------------------------

sub new {
	my $class = shift;
	my $self = {
		verbose=>0,
		errs=>'',

		sock_domain=>PF_UNIX,
		sock_type=>SOCK_STREAM,
		unix_sock=>'/tmp/ser_ctl',
		remote_host=>'localhost',
		remote_port=>2049,
		proto=>getprotobyname('udp')
	};
	return bless($self, $class);	
}

sub parse_connection_string($$) {
	my ( $self, $s ) = @_;
	$self->dbg("parse_connection_string($s)");
	my @flds = split(/:/, $s);
	if ($flds[0] eq 'unix') {
		$self->{sock_domain} = PF_UNIX;
		$self->{unix_sock} = $flds[1] if $flds[1];
		$self->{sock_type} = SOCK_STREAM;
	}
	elsif ($flds[0] eq 'udp' || $flds[0] eq 'tcp') {
		my $type;
		$self->{sock_domain} = PF_INET;
		$self->{remote_host} = $flds[1] if $flds[1];
		$self->{remote_port} = $flds[2] if $flds[2];
		$self->{proto} = (getprotobyname($flds[0]))[2];
		$self->{sock_type} = $sock_type_by_proto{$flds[0]};
	}
	else {
			$self->err("Bad protocol in \'$s\'\n");
			return 0;
	}
	return 1;
}

sub dbg($$) {
	my ( $self, $s ) = @_;
	if ($self->{verbose}) {
		print STDERR "DBG: $s\n";
	}
}


sub dbg_dump_arr ($$\@) {  # method prototypes has no effect !
	my ($self, $name, $arr) = @_;
	if ($self->{verbose}) {
		$self->dbg(sprintf("$name (length: %d):", scalar(@$arr)));
		my $s1 = '';
		my $s2 = '';
		my $i = 16;
		for my $j (0 .. $#$arr) {
			$b = $$arr[$j];
			$s1 .= sprintf('%0.2x ', $b);
			if (($b >= 0x20) and ($b<0x80)) {
				$s2 .= pack('C', $b);
			}
			else {
				$s2 .= '.';
			}
			$i--;
			if (($i & 0x0F) == 0) {
				$self->dbg("$s1   $s2");
				$s1 = '';
				$s2 = '';
				$i = 16;
			}
		}
		if ($i & 0x0F) {
			while ($i > 0) {
				$s1 .= '   ';
				$i--;
			}
			$self->dbg("$s1   $s2");
		}
		$self->dbg("END");
	}
}

sub err($$) {
	my ($self, $s) = @_;

	my @stack = caller(1);
	$self->{errs} = "$stack[3]: $s";
	$self->dbg("ERROR: $self->{errs}");
}

sub open($) {
	my ($self) = @_;
	my $sock;
	if (defined $self->{socket}) {
		$self->err("Socket is already opened");
		return 0;
	}
	if ($self->{sock_domain} == PF_UNIX) {
		$sock = IO::Socket::UNIX->new(
			Type=>$self->{sock_type},
			Peer=>$self->{unix_sock}
			#Local=>
			#Listem=>
		);
		unless ($sock) {
			$self->err("socket: $!");
			return 0;
		}
#		unless (connect(SOCKET, sockaddr_un($conn_params->{'file'}))) {
#			err(%$conn, "connect: $!");
#			close SOCKET;
#			return 0;
#		}
		$self->{socket} = $sock;
	}
	elsif($self->{sock_domain} == PF_INET) {
		my $iaddr = inet_aton($self->{remote_host});
		unless ($iaddr) {
			$self->err("no destination address for \'$self->{remote_host}\'");
			return 0;
		}
		$sock = IO::Socket::INET->new(
			PeerAddr=>$self->{remote_host},
			PeerPort=>$self->{remote_port},
			Proto=>$self->{proto},
			Type=>$self->{sock_type}
		);
		unless ($sock) {
			$self->err("socket: $!");
			return 0;
		}
#		unless (connect(SOCKET, sockaddr_in($conn_params->{'port'}, $iaddr))) {
#			err(%$conn, "connect: $!");
#			$sock->close;			
#			return 0;
#		}
		$self->{socket} = $sock;
	} else {
		$self->err("Unknown domain");
		return 0;
	}
	return 1;
}

sub close($) {
	my ($self) = @_;
	if (! defined $self->{socket}) {
		return 1;
	}
	my $sock = $self->{socket};
	unless ($sock->close) {
		$self->err("close: $!");
		return 0;
	}
	undef $self->{socket};
	return 1;
}

sub DESTROY {
	my ($self) = @_;
	$self->close();
}

sub command($$\@\@) {     # method prototypes has no effect !
	my ($self, $cmd, $params, $result) = @_;
	my $magic = 0xA;
	my $version = 1;

	if (!defined @$params) {
		my @a = ();
		$params = \@a;
	}
	$self->dbg("command: $cmd(@$params)");
	unless ($cmd) {
		$self->err("Command not specified");
		return 0;
	}
	unless (defined $self->{socket}) {
		$self->err("Socket is not opened");
		return 0;
	}
	# prepare body
	my @body = ();

	binrpc_add_str(@body, $cmd);
	foreach (@$params) {
		my $item = $_;
		my $data_type;
		if ($item =~ /^\d+$/) {
			binrpc_add_int(@body, $item);
		}
		elsif ($item =~ /^\d+\.\d+$/) {
			binrpc_add_double(@body, $item);
		} else {
			if ($item =~ /^s:/ ) {
				$item = substr($item, 2);				
			}
			binrpc_add_str(@body, $item);
		}
	}


	my $cookie = int(rand(0xFFFFFFFF));
	my $body_len = $#body+1;
	my $type = $message_type{REQ};
	if ($body_len > 0xFFFFFFFF) {
		$self->err("Body length exceeded");
		return -1;
	}
	my $len_len = binrpc_get_int_len($body_len);
	my $c_len = binrpc_get_int_len($cookie);
	if ($len_len==0) {
		$len_len=1; # we can't have 0 len
	}
	if ($c_len==0) {
		$c_len=1;  # we can't have 0 len 
	}
	my @hdr = ();
	push(@hdr, ($magic << 4) | $version);
	push(@hdr, ($type<<4)|(($len_len-1)<<2)|($c_len-1));
	#$self->dbg(sprintf("Cookie: %x, len_len=$len_len, c_len=$c_len, body_len=$body_len", $cookie));
	for (; $len_len>0; $len_len--){
		push(@hdr, ($body_len>>(($len_len-1)*8)) & 0xFF);
	}
	for (; $c_len>0; $c_len--){
		push(@hdr, ($cookie>>(($c_len-1)*8)) & 0xFF);
	}

	$self->dbg_dump_arr('header', \@hdr);
	$self->dbg_dump_arr('body', \@body);

	# flush read buffer
	my $sock = $self->{'socket'};
	$sock->flush;

	# send request
	my $buf = '';
	for my $i (0 .. $#hdr) {
		$buf .= pack('C', $hdr[$i]);
	}
	for my $i (0 .. $#body) {
		$buf .= pack('C', $body[$i]);
	}
	unless ($sock->write($buf, length($buf))) {
		$self->err("Send error: $!");
		return 0;
	}

	# read header
	unless ($sock->read($buf, 2)) {
		$self->err("Header recv error: $!");
		return 0;
	}
	# validate
	my @arr = unpack('C*', $buf);

	$self->dbg_dump_arr('magic', \@arr);
	if (($arr[0] >> 4) != $magic) {
		$self->err("Bad magic");
		return 0;
	}
	if (($arr[0] & 0x0F) != $version) {
		$self->err("Bad version");
		return 0;
	}
	$type = $arr[1] >> 4;
	$len_len = (($arr[1] >> 2) & 0x03)+1;
	$c_len = ($arr[1] & 0x03)+1;

	unless ($sock->read($buf, $len_len+$c_len)) {
		$self->err("Header length recv error: $!");
		return 0;
	}
	
	# read body len & cookie
	my $cookie2;
	@arr = unpack('C*', $buf);
	$self->dbg_dump_arr('cookie', \@arr);
	binrpc_read_int(@arr, $len_len, $body_len);
	binrpc_read_int(@arr, $c_len, $cookie2);

	if ($cookie != $cookie2) {
		$self->err("Bad cookie ($cookie!=$cookie2");
		return 0;
	}
	# read body
	unless ($sock->read($buf, $body_len)) {
		$self->err("Body recv error: $!");
		return 0;
	}

	# parse result
	@arr = unpack('C*', $buf);
	$self->dbg_dump_arr('result', \@arr);

	@$result = ();

	while (scalar(@arr)) {
		my ($val_type, $val, $dummy);
		undef $val_type;  # any type
		unless (binrpc_read_record(@arr, '', $val_type, $val, $dummy)) {
			$self->err("Parsing result error");
			return 0;
		}
		push(@$result, $val);
	}

	if ($type == $message_type{REPL}) {
		return 1;	
	}
	elsif ($type == $message_type{FAULT}) {
		return -1;
	}
	else {
		$self->err("Bad reply type ($type)");
		return 0;
	}
}

sub print_result($$\@$) {
	my ($self, $stream, $result, $indent) = @_;

	$indent = '' unless (defined $indent);
	
	if (ref($result) eq 'ARRAY') {
		for my $i (0 .. $#$result) {
			if (ref($$result[$i]) eq 'ARRAY') {
				printf $stream "%s(\n", $indent;
				$self->print_result($stream, $$result[$i], "$indent  ");
				printf $stream "%s)\n", $indent;
			} elsif (ref($$result[$i]) eq 'HASH') {
				printf $stream "%s\{\n", $indent;
				$self->print_result($stream, $$result[$i], "$indent  ");
				printf $stream "%s}\n", $indent;

			} else {
				printf $stream "%s%s\n", $indent, $$result[$i];
			}

		}
	} elsif (ref($result) eq 'HASH') {
		foreach my $k (keys %$result) {
			printf $stream "%s%s: %s\n", $indent, $k, $result->{$k};
		}
	} else {
		printf $stream "%s%s\n", $indent, $$result;
	}
	
}


# ----------------------------- end of object ------------------------------------

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ser::BinRPC - Perl extension for Ser SIP router controlling via BinRPC protocol

=head1 SYNOPSIS

  use Ser::BinRPC;

=head1 DESCRIPTION

Ser::BinRPC provides an object interface to controlling SER (Sip Express Router) or SIP-Router
(http://www.sip-router.org) via binary RPC (BinRPC) protocol. The BinRPC is light-weighted RPC protocol provided
by ctl module. Unix, UDP and TCP network protocols are supported.

=head1 CONSTRUCTOR

=over 4

=item new ()

The constructor takes no arguments. Assign default field values.

=back

=head1 FIELDS

=over 4

=item verbose

Print more verbose messages at STDERR. Default: 0

=item sock_domain

Type of socket domain (PF_UNIX .. default, PF_INET)

=item sock_type

Socket type (SOCK_STREAM .. default, SOCK_DGRAM)

=item unix_sock

Name of remote socket, default: '/tmp/ser_ctl'

=item remote_host

Name of remote host for UDP/TCP connection, default: 'localhost'

=item remote_port

Port for UDP/TCP connection, default: 2049

=item proto

Protocol ('udp'..default, 'tcp')

=item errs

If a method fails then returns 0 and reason is stored in errs field.

=back

=head1 METHODS

=over 4

=item parse_connection_string ($string)

Parse connection string, syntax:

  "unix" [ ":" [ unix_sock ] ]
  ("tcp" | "udp") [ ":" [ remote_host ] ":" [ remote_port ] ]

If a value is omited then current value remains unchanged. Example:

  $self->parse_connection_string('udp:127.0.0.2:2050');

  $self->parse_connection_string('unix:/tmp/ser_ctl2');


=item open ()

Open socket connection.

=item close ()

Close socket connection.

=item command ( $cmd , \@cmd_params, \@result )

Do RPC command and get result. If OK then returns 1,
if RPC server returns error code then return value is -1.
Result contains array of values (scalar, array, hash).
Values may be nested.

Example:

  use Socket;
  use Ser::BinRPC;

  my $conn = Ser::BinRPC->new();

  $conn->{domain} = PF_INET;
  $conn->{remote_host} = 'localhost';
  $conn->{remote_port} = 2050;
  $conn->{proto} = 'tcp';
  $conn->{sock_type} = SOCK_STREAM;

  # or
  # $conn->parse_connection_string('tcp:localhost:2050');

  my $ret = $conn->command('core.uptime', [ ], \@result);
  if ($ret > 0) {

    $conn->print_result(\*STDERR, \@result);

    printf("Server uptime is %d\n", $res[0]->{'uptime'});

  } elsif ($ret < 0) {
    # RPC error
    printf STDERR "%d - %s", $result[0], $result[1];
  } else {
    die $conn->{errs};
  }

=item print_result ( \*STREAM, \@result, [$prefix] )

Print result in human readable form.

=back

=head2 EXPORT

None by default.


=head1 SEE ALSO

SER: http://www.iptel.org/ser/, SIP-Router: http://www.sip-router.org

=head1 AUTHOR

Tomas Mandys, <lt>tomas.mandys@2p.cz<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tomas Mandys

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
