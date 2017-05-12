package Net::ManageSieve;

=head1 NAME

Net::ManageSieve - ManageSieve Protocol Client

=head1 SYNOPSIS

    use Net::ManageSieve;

    # Constructors
    $sieve = Net::ManageSieve->new('localhost');
    $sieve = Net::ManageSieve->new('localhost', Timeout => 60);

=head1 DESCRIPTION

This module implements a client interface to the ManageSieve protocol
(L<http://tools.ietf.org/html/draft-martin-managesieve-09>). This
documentation assumes that you are familiar with the concepts of the
protocol.

A new Net::ManageSieve object must be created with the I<new> method. Once
this has been done, all ManageSieve commands are accessed through
this object.

I<Note>: ManageSieve allows one to manipulate scripts on a host running a
ManageSieve service, this module does not perform, validate or something
like that Sieve scipts themselves.

This module works in taint mode.

=head1 EXAMPLES

This example prints the capabilities of the server known as mailhost:

    #!/usr/local/bin/perl -w

    use Net::ManageSieve;

    $sieve = Net::ManageSieve->new('mailhost');
    print "$k=$v\n" while ($k, $v) = each %{ $sieve->capabilities };
    $sieve->logout;

This example lists all storred scripts on the server and requires TLS:

    #!/usr/local/bin/perl -w

    use Net::ManageSieve;

    my $sieve = Net::ManageSieve->new('mailhost', tls => 'require')
      or die "$@\n";
    print "Cipher: ", $sieve->get_cipher(), "\n";
    $sieve->login('user', 'password')
      or die "Login: ".$sieve->error()."\n";
    my $scripts = $sieve->listscripts
      or die "List: ".$sieve->error()."\n";
    my $activeScript = pop(@$scripts);
	print "$_\n" for sort @$scripts;
    print $activeScript
      ? 'active script: ' . $activeScript
      : 'no script active'
     , "\n";
    $sieve->logout;

=head1 ERROR HANDLING

By default all functions return C<undef> on failure and set an
error description into C<$@>, which can be retrieved with the
method C<error()> as well.

The constructor accepts the setting C<on_fail>, which alters this
behaviour by changing the step to assign C<$@>:
If its value is:

=over 4

=item C<warn>

the program carps the error description.

If C<debug> is enabled, too, the description is printed twice.

=item C<die>

the program croaks.

=item is a CODE ref

this subroutine is called with the arguments:

 &code_ref ( $object, $error_message )

The return value controls, whether or not the error message will be
assigned to C<$@>. Private functions may just signal that an error
occurred, but keep C<$@> unchanged. In this case C<$@> remains unchanged,
if code_ref returns true.

I<Note>: Even if the code ref returns false, C<$@> might bi clobberred
by called modules. This is especially true in the C<new()> constructor.

=item otherwise

the default behaviour is retained by setting C<$@>.

=back

=cut

require 5.001;

use strict;
use vars qw($VERSION @ISA);
use Socket 1.3;
use Carp;
use IO::Socket;
use Encode;

$VERSION = "0.13";

@ISA = qw();

=head1 CONSTRUCTOR

=over 4

=item new ( [ HOST ] [, OPTIONS ] )

This is the constructor for a new Net::ManageSieve object. C<HOST> is the
name of the remote host to which an ManageSieve connection is required.

C<HOST> is optional. If C<HOST> is not given then it may instead be
passed as the C<Host> option described below. If neither is given then
C<localhost> will be used.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Host> - ManageSieve host to connect to. It may be a single scalar,
as defined for the C<PeerAddr> option in L<IO::Socket::INET>, or a
reference to an array with hosts to try in turn. The L</host> method
will return the value which was used to connect to the host.

B<LocalAddr> and B<LocalPort> - These parameters are passed directly
to IO::Socket to allow binding the socket to a local port.

B<Timeout> - Maximum time, in seconds, to wait for a response from the
ManageSieve server (default: 120)

B<Port> - Select a port on the remote host to connect to (default is 2000)

B<Debug> or B<debug> - enable debugging if true (default OFF)

I<Note>: All of the above options are passed through to L<IO::Socket::INET>.

B<tls> - issue STARTTLS right after connect. If B<tls> is a HASH ref,
the mode is in member C<mode>, otherwise C<tls> itself is the mode and
an empty SSL option HASH is passed to L<starttls()>. The C<mode> may be
one of C<require> to fail, if TLS negotiation fails, or C<auto>,
C<on> or C<yes>, if TLS is to attempt, but a failure is ignored.
(Aliases: B<TLS>, B<Tls>)

B<on_fail> - Changes the error handling of all functions that would
otherwise return undef and set C<$@>. See section ERROR HANDLING
(Aliases: B<On_fail>)

Example:

    $sieve = Net::ManageSieve->new('mailhost',
			   Timeout => 30,
	);

use the first host one can connect to successfully C<mailhost> on port
C<2000>, the default port, then C<localhost> on port C<2008>.

    $sieve = Net::ManageSieve->new(Host => [ 'mailhost', 'localhost:2008' ],
			   Timeout => 30,
			   tls => {
			   	mode => require,
			   	SSL_ca_path => '/usr/ssl/cert',
			   }
	);

=back

=cut

sub _decodeCap ($$) {
	my $self = shift;
	my $cap = shift;

	if(ref($cap) eq 'ARRAY') {
		$self->{capabilities} = { };
		while(my $c = shift(@$cap)) {
			next if ref($c);
			$c = lc($c);	# capability-name
			my @v;
			while(my $v = shift(@$cap)) {	# quaff even multiple tokens
				last if ref($v);#CRLF	# standard allows one
				push(@v, $v);			# optional value
			}	# lasr CRLF had been quaffed by ok() already
			$self->{capabilities}->{$c}
			 = scalar(@v)? join(',', @v)
			             : '0 but true';
		}
	}

	return $self;
}

sub new {
	my $self = shift;
	my $type = ref($self) || $self;
	$self = bless {}, $type;

	my ($host,%arg);
	if(@_ % 2) {
		$host = shift ;
		%arg  = @_;
	} else {
		%arg = @_;
		$host = delete $arg{Host};
	}
	$host ||= 'localhost';
	$arg{Proto} ||= 'tcp';
	$arg{Port} ||= 'managesieve(2000)';
	$arg{PeerPort} = $arg{Port};
	$arg{Timeout} = 120 unless defined $arg{Timeout};
	$self->{timeout} = $arg{Timeout};
	$self->{_last_response} = 'OK no response, yet';
	$self->{_last_error} = '';
	$self->{_last_command} = '';
	$self->{_debug} = 1 if $arg{Debug} || $arg{debug};
	$self->{_on_fail} = delete $arg{on_fail} || delete $arg{On_fail};
	$self->{_tls} = delete $arg{tls} || delete $arg{Tls} || delete $arg{TLS}; 

	foreach my $h (@{ref($host) ? $host : [ $host ]}) {
		$arg{PeerAddr} = $h;
		if($self->{fh} = IO::Socket::INET->new(%arg)) {
			$self->{host} = $h;
			last;
		}
	}

	unless(defined $self->{host}) {
		my $err = $@;
		$err = 'failed to connect to host(s): '.$! unless defined $err;
		$self->_set_error($err);
		return undef;
	}

	$self->{fh}->autoflush(1);

	# Read the capabilities
	my $cap = $self->_response();
	return undef unless $self->ok($cap);
	$self->_decodeCap($cap);

	if(my $mode = $self->{_tls}) {
		my $tls;	
		if(ref($mode) eq 'HASH') {
			$tls = $mode;
			$mode = delete $tls->{mode} || 'auto';
		} else {
			$tls = { };	# no arguments
		}

		if($mode && $mode =~ /\A(?:require|auto|yes|on|y)\Z/) {
			my $rc = $self->starttls(%$tls);
			if(!$rc && $mode eq 'require') {
				my $err = $@;
				$err = 'unknown error' unless defined $err;
				$self->_set_error('failed to enable TLS: '.$err);
				return undef;
			}
		}
	}

	return $self; 
}

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When
a method states that it returns a value, failure will be returned as
I<undef> or an empty list. The error is specified in C<$@> and can be
returned with the L</error> method. Please see section ERROR HANDLING
for an alternative error handling scheme.

=over 4

=item close ()

Closes the connection to the server. Any already cached data is kept
active, though, there should be no pending data, if an user calls this
function.

=cut

sub close {
    my $self = shift;
	return undef unless $self->{fh};
	my $rc = $self->{fh}->close();
	delete $self->{fh};
	return $rc;	# we keep locally cached data intentionally
}

=item starttls ( %SSL_opts )

Initiates a TLS session, may be used only before any
authentication.

The C<SSL_opts> is a HASH containing any options you can
pass to L<< IO::Socket::SSL->new() >>. No one is passed by default.

In order to detect in the later run, if the connection is encrypted,
use the C<encrypted()> function.

Return: $self or C<undef> on failure - the socket is still
functioning, but is not encrypted.

=cut

sub starttls {
	my $self = shift;
	unless(scalar(@_) % 2 == 0) {
		$@ = 'The argument list must be a HASH';
		return undef;
	}
	my %opts = @_;

	return undef unless $self->ok($self->_command("STARTTLS"));

	# Initiate TLS 
	unless(defined &IO::Socket::SSL::new) {
		eval { require IO::Socket::SSL };
		if($@) {
			$self->_set_error('cannot find module IO::Socket::SSL', 'skipAd');
			return undef;
		}
	}

	IO::Socket::SSL->start_SSL($self->{fh} , %opts);
	# In-place upgrade of socket
	return undef unless ref($self->{fh}) eq 'IO::Socket::SSL';

	# success, state now is the same as right after connect
	my $cap = $self->_response();
	return undef unless $self->ok($cap);
	$self->_decodeCap($cap);

	return $self;
}

=item encrypted ()

Returns C<undef>, if the connection is not encrypted, otherwise
C<true>.

=cut

sub encrypted {
	my $fh = $_[0]->{fh};
	return $fh && ref($fh) && $fh->isa('IO::Socket::SSL');
}


=item get_cipher (), dump_peer_certificate (), peer_certificate ($field)

Returns C<undef>, if the connection is not encrypted, otherwise
the functions directly calls the equally named function
of L<IO::Socket::SSL>.

=cut

sub _encrypted {
	my $fh = $_[0]->{fh};
	unless($fh) {
		$_[0]->_set_error('no connection opened');
		return undef;
	}
	unless(encrypted($_[0])) {
		$_[0]->_set_error('connection not encrypted');
		return undef;
	}
	return $fh;
}

sub get_cipher {
	return undef unless &_encrypted;
	return $_[0]->{fh}->get_cipher();
}
sub dump_peer_certificate {
	return undef unless &_encrypted;
	return $_[0]->{fh}->dump_peer_certificate();
}
sub peer_certificate {
	return undef unless &_encrypted;
	shift;
	return $_[0]->{fh}->peer_certificate(@_);
}

=item auth (USER [, PASSWORD [, AUTHNAME ] ])

Authentificates as C<USER>.

If the module L<Authen::SASL> is available, this module is tried first. In
this case, the C<USER> parameter may be a C<Authen::SASL> object, that
is not furtherly modified. If C<USER> is no C<Authen::SASL> object, 
C<USER> is passed as C<user>, C<PASSWORD> as C<pass> and C<AUTHNAME>
as C<authname> to C<< Authen::SASL->new() >>. If C<AUTHNAME> is
undefined, C<USER> is passed as C<authname>. This way you can
authentificate against Cyrus: C<auth('cyrus', $password, $username)>.

If L<Authen::SASL> is I<not> available or the initialization of it fails,
this function attempts to authentificate via the C<PLAIN> method.

Aliases: C<login>, C<authentificate>.

=cut

sub _encode_base64 {
	my $self = shift;

	unless(defined &MIME::Base64::encode_base64) {	# Automatically load it
		eval { 	require MIME::Base64; };
		if($@) {
			$self->_set_error('failed to load MIME::Base64: ' . $@);
			return undef;
		}
	}

	my $r = &MIME::Base64::encode_base64;
	$r and $r =~ s/[\s\r\n]+$//s;
	return $r;
}
sub auth {
	my ($self, $username, $password, $authname) = @_;
    
    if(my $mech = $self->{capabilities}{sasl}) {
     # If the server does not announce SASL, we try PLAIN anyway
		my $doSASL = 1;
		unless(defined &Authen::SASL::new) {	# Automatically load it
			eval { 	require Authen::SASL; };
			if($@) {
				$self->_set_error("failed to load Authen::SASL: $@\nFallback to PLAIN\n");
				$doSASL = undef;
			}
		}
		if($doSASL) {
			my $sasl;
			if(ref($username) && UNIVERSAL::isa($username, 'Authen::SASL')) {
				$sasl = $username;
#				$sasl->mechanism($mech);
			} else {
				unless(length $username) {
					$self->_set_error("need username or Authen::SASL object");
					return undef;
				}
				unless(defined $authname) {
					$authname = $username;
				}
				# for unknown reason to pass in a space
				# separated string leads to the problem
				# that $client->mechnism returns the same
				# string, but ought to return the _used_
				# mechnism only therefore, we use the
				# first one of the list
				# 2008-04-25 ska
				$mech =~ s/\s.*//;
#				$mech = "LOGIN";
				$sasl = Authen::SASL->new(mechanism=> "".$mech, # without "". the behaviour is funny
					callback => { user => $username,
						pass => $password,
						password => $password,	# needed it to work properly
						authname => $authname,
					}
				);
			}

			# draft-martin-managesieve-08: service := 'sieve'
			my $client = $sasl->client_new('sieve', $self->{host}, 0);
			# I did understood the documentation that way that
			# 'undef' means error, this is wrong. client_start() returns
			# undef for no initial client response.
			my $msg = $client->client_start;
			if($client->mechanism) {
				if($msg) {
					return undef
					 unless defined($msg = $self->_encode_base64($msg,''));
					$msg = ' "' . $msg . '"';
				} else {
					$msg = '';	# Empty initial request
					# Force to load MIME::Encode
					return undef unless defined $self->_encode_base64('z');
				}
				# Initial response
				$self->_send_command(
				  'Authenticate "'. $client->mechanism . '"' . $msg)
				 or return undef;
				while($msg = $self->_token()) {
					if(ref($msg)) {	# end of command received	OK|NO
						next if $msg->[0] eq "\n";	#CRLF is a token
						$msg = $self->ok([ $msg ]);
						last;
					}
					# MIME::Base64 is definitely loaded here
					$self->_write(
					  '"' . $self->_encode_base64(
						$client->client_step(
						  MIME::Base64::decode_base64($msg)
						), ''
					  ) . "\"\r\n"
					);
				}

				return $msg if $msg;
				$self->_set_error('SASL authentification failed');
				return undef;
			}
			$self->_set_error("start of SASL failed");
			# Circumvent SASL problems by falling back to plain PLAIN
		}
    }

	my $r = $self->_encode_base64(
	  join("\0", ($username, $username, $password))
	  , '');
	return undef unless defined $r;
	return $self->ok($self->_command('Authenticate "PLAIN" "'.$r.'"'));
}
sub login { goto &auth; }
sub authentificate { goto &auth; }

=item logout ()

Sends the C<LOGOUT> command to the server and closes the
connection to the server.

Aliases: C<quit>, C<bye>.

=cut

sub logout {
	my ($self) = @_;

	return 1 unless $self->{fh};
	my $rc = $self->_command("LOGOUT");
	$self->close();
	return $self->ok($rc, 'bye');
}
sub quit { goto &logout; }
sub bye { goto &logout; }

=item host ()

Returns the remote host of the connection.

=cut

sub host {
	my ($self) = @_;

	return $self->{host};
}

=item capabilities ([reget])

Returns the capabilities as HASH ref, e.g.:

	{
	  'starttls' => 1,
	  'sasl' => 'PLAIN LOGIN',
	  'implementation' => 'dovecot',
	  'sieve' => 'fileinto reject envelope vacation imapflags notify subaddress relational comparator-i;ascii-numeric regex'
	};

If the argument C<bool> is specified and is boolean C<TRUE>,
the capabilities are reaquired from the server using
the I<CAPABILITY> command.
Note: The initial capabilities may be different from the set
acquired later.

=cut

sub capabilities {
	my ($self, $reget) = @_;

	if($reget) {
		my $cap = $self->_command("CAPABILITY") or return undef;
		return undef unless $self->ok($cap);
		$self->_decodeCap($cap);
	}
	return $self->{capabilities};
}

=item havespace (NAME, SIZE)

Return whether or not a script with the specified size (and name)
might fit into the space of the user on the server.

Due to various reasons, the result of this function is not very
reliable, because in the meantime lots of changes may take place
on the server.

=cut

sub havespace {
	my ($self, $name, $size) = @_;

	unless($size =~ /\A\d+\Z/) {
		$self->_set_error("size is not numeric: $size");
		return undef;
	}
	return undef unless $name = $self->_chkName($name);
	return $self->ok($self->_command("HAVESPACE $name $size"));
}

=item putscript (NAME, SCRIPT)

Stores the C<SCRIPT> as name C<NAME> on the server, the script
is I<not> activated by default. C<SCRIPT> is a scalar in UTF-8.

The script must not be empty.

=cut

sub putscript {
	my ($self, $name, $script) = @_;

	$script = Encode::encode_utf8($script);	# need octets
	$script .= "\n" unless $script =~ /\n\Z/;
	return undef unless $name = $self->_chkName($name);
	return $self->ok($self->_command("PUTSCRIPT $name "
	 . _literal($script)));
}

=item listscripts ()

returns an ARRAY ref of the names of the scripts.

The last entry in the list, specifies the active script, it is
an empty string C<"">, if there is none.

e.g.:

	[	"script1",
		"script2",
		"script1"
	]

means that C<script1> is active currently.

=cut

sub listscripts {
	my ($self) = @_;

	my $r = $self->_command("LISTSCRIPTS") or return undef;

	unless(my $rc = $self->ok($r)) {
		return $rc;
	}

	my $c = [ ];
	my $act = '';	# Default: no active script
	my $last;
	for(@$r) {
		if(ref($_)) {	# active flag or CRLF
			$act = $last if $_->[0] eq 'ACTIVE';
		} else {
			push(@$c, $last = $_);
		}
	}

	push(@$c, $act);

	return $c;
}

=item setactive (NAME)

Activates the script named C<NAME>.

=cut

sub setactive {
	my ($self, $name) = @_;

	return undef unless $name = $self->_chkName($name);
	return $self->ok($self->_command("SETACTIVE $name"));
}

=item getscript (NAME)

Returns the named script. The contents is in perl-internal UTF8.

=cut

sub getscript {
	my ($self, $name) = @_;

	return undef unless $name = $self->_chkName($name);
	my $r = $self->_command("GETSCRIPT $name") or return undef;

	if($self->ok($r)) {
		my $l = join("\n", @$r);
		$l =~ s/[\s\r\n]+\Z//s;
		$l .= "\n";
		return $l;
	}
	return undef;
}

=item deletescript (NAME)

Deletes the script named C<NAME>.

=cut

sub deletescript {
	my ($self, $name) = @_;

	return undef unless $name = $self->_chkName($name);
	return $self->ok($self->_command("DELETESCRIPT $name"));
}

=item error ()

Returns the locally cached error information in the form:

 error description respn=last server response

=cut

sub error {
	my ($self) = @_;

	return $self->{_last_error} . '; cmd=' . $self->{_last_command}
	 . '; rspn=' . join(' ', @{ $self->{_last_response} });
}

=begin COMMENT

arg1 :- error string, always != undef
arg2 :- if passed, but not true: DO NOT assign $@

See ERROR HANDLING about C<_on_fail>

=end COMMENT

=cut

sub _set_error {
	my ($self, $err, $Ad) = @_;

	dbgPrint('ERROR:', $err) if $self->{_debug};
	$self->{_last_error} = $err;
	my $assignAd = !defined $Ad || $Ad;
	my $op = $self->{_on_fail} if exists $self->{_on_fail};
	if(defined($op) && ref($op) eq 'CODE') {
		$assignAd &&= $op->($self, $err);
	} elsif(defined($op) && $op eq 'warn') {
		Carp::carp $err;
	} elsif(defined($op) && $op eq 'die') {
		Carp::croak $err."\n";
	# } else {
	}
	$@ = $err if $assignAd;

	return $self;
}

=item debug ( [state] )

Returns the current state of debugging.

If C<state> is given, the boolean value enables or
disables debugging.

=cut

sub debug {
	my ($self, $state) = @_;

	my $rc = $self->{_debug};
	if(defined $state) {
		if($state) {
			$self->{_debug} = 1;
		} else {
			delete $self->{_debug};
		}
	}

	return $rc;
}

=begin COMMENT

arg1 :- Prefix
arg2 :- passed through Data::Dumper

=end COMMENT

=cut

sub dbgPrint {
	my ($prefix, $msg) = @_;

	my $txt = '';
	$txt .= $prefix . ' ' if $prefix;
	MANGLE: { if($msg) {
		unless(defined &Data::Dumper::Dump) {
			eval "require Data::Dumper";
			if($@) {
				$txt .= 'Failed to require Data::Dumper';
				last MANGLE;
			}
		}
		my $d = Data::Dumper->new([$msg], []);
		$txt .= $d->Indent(1)->Terse(1)->Sortkeys(1)->Dump;
	} }

	if($txt) {
		print STDERR $txt;
		print STDERR "\n" unless $txt =~ /\n$/s;
	}
}

#############################


sub _literal {
	my $str = shift;
	$str = shift if ref($str);

	# [1] We send non-synchronizing literals: "+}CRLF"
	return '{' . length($str) . '+}' . "\r\n" . $str;
}

sub _chkName {
	my $self = shift;
	my $name = shift;

	if(ref($name)) {
		$self->_set_error("need a scalar");
		return undef;
	}

	if($name =~ /[\0\r\n]/) {
		$self->_set_error("invalid character in name");
		return undef;
	}

	return _literal($name) if $name =~ /[\\"[:cntrl:]]/;
	return '"' . $name . '"';
}

sub _send_command {
	my ($self, $cmd) = @_;

	if($cmd =~ /\A(\S+)/) {
		$self->{_last_command} = $1;
	}
	$self->_write($cmd."\r\n");
}
sub _command {
	return &_send_command && &_response;
}

sub ok {
	my $self = shift;
	my $c = shift;
	my $okRsp = shift;
	my $cmt;

	return undef unless defined $c;

	if(ref($c)) {
		unless(ref($c) eq 'ARRAY') {
			$self->_set_error("response code must be ARRAY ref or SCALAR");
			return undef;
		}
		my $cx = pop(@$c);
		if(defined(my $cy = pop(@$c))) {
			push(@$c, $cy)	# Remove the CRLF preceeding the OK/NO
			 if ref($cy) ne 'ARRAY' || $cy->[0] ne "\n";
		}
		if(ref($cx) eq 'ARRAY') {
			$cmt = join("; ", @$cx);
			$c = $cx->[0];
		} else {
			$c = $cx;
		}
	}
	$cmt ||= $c;

	unless($c =~ /\A(OK|NO|BYE)\b/i) {
		$self->_set_error("invalid response: $cmt");
		return undef;
	}
	return $c if uc($1) eq 'OK'
	 || defined($okRsp) && uc($okRsp) eq uc($1);	# e.g. LOGOUT gets BYE

	$self->_set_error("command failed with '$cmt'");
	return 0;	# Failed
}

sub _write {
	my ($self, $l) = @_;

	my $fh = $self->{fh};
	unless($fh) {
		$self->_set_error("no connection open");
		return undef;
	}

	my $len = length($l);
	dbgPrint('WRITE:', $l) if $self->{_debug};
	local $SIG{PIPE} = 'IGNORE' unless $^O eq 'MacOS';
	my $in = ''; # For select
	vec($in, fileno($fh), 1) = 1;
	my $timeout = $self->{timeout} || undef;
	my $offset = 0;

	while($len) {
		if(select(undef, $in, undef, $timeout) > 0) {
			my $w = syswrite($fh, $l, $len, $offset);
			unless(defined($w)) {
				$self->_set_error("write failed: $!");
				return undef;
			}
			$len -= $w;
			$offset += $w;
		} else {
			$self->_set_error("write timeout");
			return undef;
		}
	}

	return 1;
}

sub _response {
	my ($self) = @_;

	my $l = [];
	GET_LOOP: {
		defined(my $r = $self->_token()) or return undef;
		push(@$l, $r);
		redo GET_LOOP
		 if !ref($r)		# string
		  || $r->[0] =~ /^(?:\n|active)$/i	# CRLF; ACTIVE: LISTSCRIPTS
		;
		# OK|NO|BYE -> end loop
	}

	return $l;
}

sub _unget {
	my $self = shift;

	return $self unless scalar @_;

	unless(ref($self->{line_buffer}) eq 'ARRAY') {
		$self->{line_buffer} = [ @_ ];
	} else {
		unshift @{$self->{line_buffer}}, @_;
	}
	return $self;
}

sub _getline {
	my ($self) = @_;

	unless(ref($self->{line_buffer}) eq 'ARRAY') {
		$self->{line_buffer} = [ ];
	}

	return shift @{$self->{line_buffer}}
	 if scalar(@{$self->{line_buffer}});

	my $fh = $self->{fh};
	unless($fh) {
		$self->_set_error("no connection open");
		return undef;
	}

	local $SIG{PIPE} = 'IGNORE' unless $^O eq 'MacOS';
	my $out = ''; # For select
	vec($out, fileno($fh), 1) = 1;
	my $timeout = $self->{timeout} || undef;
	my $buf = $self->{pending_line} || '';

	until(scalar(@{$self->{line_buffer}})) {
		if(select($out, undef, undef, $timeout)) {
			unless(sysread($fh, $buf, 64 * 1024, length($buf))) {
				$self->_set_error("socket empty although there is data pending: $!");
				$self->close();
				return undef;
			}
			while($buf =~ s/\A(.*?\r*\n)//s) {
				#my $l = $1;		# one full line within the CRLF
				push(@{$self->{line_buffer}}, $1);
			}
		} else {
			$self->_set_error("read socket timeout");
			return undef;
		}
	}
	$self->{pending_line} = $buf;

#print STDERR "Read line: $_" for @{$self->{line_buffer}};
#print STDERR "Pending line: $buf\n";

	dbgPrint('READ:', join('', @{$self->{line_buffer}})) if $self->{_debug};
	return shift @{$self->{line_buffer}};
}

=for comment Returns a plain quoted string as SCALAR or a keyword or CRLF
as HASH ref [ keyword, string / arguments ]

=cut

sub _token {
	my ($self, $mode) = @_;

	my $l = '';
	until($l) {
		$l = $self->_getline();
		return undef unless defined $l;

		$l =~ s/\A[[:blank:]]+//;
	}

	if($l =~ /\A\{(\d+)\+?\}\r*\Z/) {	# The next $1 octets are the token
		my $cnt = $1;
		$l = '';
		while($cnt > 0) {	# Need some characters still
			# ManageSieve is line oriented, hence, we can use _getline()
			my $r = $self->_getline();
			return undef unless defined $r;
			$l .= $r;
			$cnt -= length($r);
		}
		if($cnt < 0) {		# Read too much
			$self->_unget(substr($l, $cnt));
#			$l = substr($l, 0, length($l) + $cnt);
			substr($l, $cnt) = '';
		}
	} elsif($l =~ s/\A"//) {	# quoted string
		# I interprete http://tools.ietf.org/html/draft-martin-managesieve-08#section-4
		# so that a quoted string must not cross line boundaries
		# that makes parsing easier
		unless($l =~ s/\A((?:[^"\\]|\\.)*)"//) {
			$self->_set_error("missing final quote on line: $l");
			return undef;
		}
		$self->_unget($l);
		$l = $1;
		$l =~ s/\\(.)/$1/gs;
	} elsif((!defined($mode) || $mode ne 'end')
	 && $l =~ s/\A(active|ok|no|bye)\b//i) {	# response codes
		my $r = $l;
		$l = [ $1 ];
		if(uc($1) eq 'BYE') {
			$self->close();
		}
		if($r =~ s/\A\s+(\(.+?\))//) {
			push(@$l, $1);
		}
		$self->_unget($r);
		while($r = $self->_token('end')) {	# prevent recursion of bad server response
			if(ref($r)) {	# should be NEWLINE
				last;
			} else {
				push(@$l, $r);
			}
		}
		$self->{_last_response} = deep_copy($l);
	} elsif($l =~ s/\A(\r*\n)//s) {
		$self->_unget($l) if $l;
		$l = [ "\n", $1 ];
	} else {
		$self->_set_error("invalid token: $l");
		return undef;
	}

	# Communication is in UTF8
	return ref($l)? $l: str2utf8($l);
}

#############################################
#### Helpers       ##########################
#############################################

sub deep_copy {
        my $this = shift;
        if(!ref($this) || ref($this) eq 'CODE') {
                $this;
        } elsif(ref $this eq "ARRAY") {
                [map deep_copy($_), @$this];
        } elsif(ref $this eq "HASH") {
                +{map { $_ => deep_copy($this->{$_}) } keys %$this};
        } else {
                die "what type is $_?"
        }
}

=item C<< str2utf8([encoding,] string) >>

Encodes the string into internal UTF8.

If encoding is specified, it is tried first; then C<utf-8-strict>, and,
if all fails, C<Latin1>, which is not fail.

=cut

sub __decode {
	my $enc = shift;
	my $str = shift;

	undef $@;
	return undef unless defined $str;
	return $str unless $enc;

	my $string = $str;	# enforce a local copy of the string
	my $h;
	#my $error;
	eval { $h = decode($enc, $string, Encode::FB_QUIET ); };
	# next won't work
	# eval { $h = decode($enc, $string, sub { $error = 1; die "Invalid char " . (shift()+0) . "\n" } ); };

	my $e = $@;
#	print "__decode($enc): \$\@:", (defined $e? $e||'': '<<undef>>'), " len(string)=", length($string), "\n";
	#if($error && !$e) {
	#	print "add \$\@\n";
	#	$e = "some error";
	#}
	$@ = $e;
	return $h if $e || length($string) == 0;
	if($string eq $str) {# the string had been decoded wholly 
		return $h if $h || !$h && !$str;
	}
	$@ = length($string) . ' characters not decoded';
	return undef;
}
sub str2utf8 ($;$) {
	my $enc;
	if(scalar(@_) > 1) {
		$enc = shift;
	}
	my $string = shift;

	return undef unless defined $string;

	my $h;
	if($enc) {	
		$h = __decode($enc, $string);
		unless($@) {
#			print "Decoded as $enc\n";
			return $h;
		}
		if($enc eq 'iso-2022-jp') {
			# Don't know why but most of the above enceded string decode with next
			$h = __decode('shiftjis', $string);
			unless($@) {
#				print "Decoded as shiftjis\n";
				return $h;
			}
		}
	}

	$h = __decode('utf-8-strict', $string);
	unless($@) {
#		print "Decoded as utf8\n";
		return $h;
	}

#	 print "Decode from latin1\n";
	$h = $string;	# enforce copy
	# For some reason, decode('latin1', ...) is doing nothing
#	Encode::from_to($h, "iso-8859-1", "utf8");
	utf8::upgrade($h);	# set the UTF8 flag
	return $h;
}

sub DESTROY
{
	my $self = shift;
	$self->close();
}

1;

__END__

=back

=head1 BUGS

The modules tries hard to pass valid UTF8 data to the server and
transforms the results into perl internal UTF8. If latter fails,
the transmitted octets are decoded using Latin1.

Script names, user names and passwords are not checked or
"SASLprep"'ed (RFC 4013/3454). Script names with C<[\0\r\n]>
are rejected.

We accept non-synchronizing literals C<{num+}> from the server.

=head1 SEE ALSO

L<http://tools.ietf.org/html/draft-martin-managesieve-09>

=head1 AUTHOR

Steffen Kaiser
This module heavily bases on L<Net::SMTP> and L<Net::Cmd>.

=head1 COPYRIGHT

Copyright (c) 2008-2010 Steffen Kaiser. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
