# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Authen.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 3849 $ $DateTime: 2003/01/25 19:36:01 $

package OurNet::BBS::Authen;
$OurNet::BBS::Authen::VERSION = '0.4';

use strict;
no warnings 'deprecated';
use RPC::PlServer::Comm;
use fields qw/gnupg who pass login keyid user challenge/;

use enum qw/BITMASK:CIPHER_ NONE BASIC PGP/;
use enum qw/BITMASK:AUTH_ NONE CRYPT PGP/;

my $i = 0;

our $OP = {
    # STATUS Operators
    (map { ("STATUS_$_" => $i++ ) } (
        qw/FAILED OK ACCEPTED FORBIDDEN IGNORED UNKNOWN_OP/,
	qw/NO_USER NO_PUBKEY BAD_PUBKEY BAD_SIGNATURE/,
    )),
    # HASH Operators
    (map { ("HASH_$_" => $i++ ) } (
	qw/FETCH FIRSTKEY NEXTKEY DESTROY FETCHARRAY/,
	qw/DEREFERENCE STORE DELETE EXISTS/,
    )),
    # ARRAY Operators
    (map { ("ARRAY_$_" => $i++) } (
        qw/FETCH DESTROY FETCHARRAY SHIFT UNSHIFT PUSH POP/,
        qw/DEREFERENCE STORE DELETE EXISTS FETCHSIZE/,
    )),
    # OBJECT Operators (the usual ones)
    (map { ("OBJECT_$_" => $i++ ) } (
        qw/SPAWN DESTROY new refresh refresh_meta board id/,
	qw/backend remove purge name ego writeok readok daemonize/,
	qw/CACHE/,
    )),
    # CODE Operators
    (map { ("CODE_$_" => $i++ ) } (
	qw/EXECUTE/,
    )),
};

our $OPREV = { 
    map { $OP->{$_} => substr($_, index($_, '_') + 1) } 
    keys %{$OP} 
};

our $Pubkey;

$OP = { %{$OP}, reverse %{$OP} };

sub load_ok {
    return ($^O ne 'MSWin32' and eval("use $_[-1]; 1"));
}

sub new {
    my ($class, $who, $pass) = @_;
    my $self = fields::new($class);

    $self->{who} = $who or die "need recipients";

    if (load_ok('GnuPG::Interface')) {
	$self->{gnupg} = GnuPG::Interface->new;
	$self->{gnupg}->options->hash_init(armor => 1, always_trust => 1);
	$self->{gnupg}->options->meta_interactive(0);
	$self->{gnupg}->options->push_recipients($who);
	$self->{gnupg}->passphrase($self->{pass} = $pass) if defined $pass;
    }

    return $self;
}

sub export_key {
    my $self = shift;

    return scalar `gpg --armor --export $self->{keyid}`;
}

sub test {
    my $self = shift;
    return ($self->{gnupg} and $self->{gnupg}->test_default_key_passphrase);
}

# query for existing BCB ciphers
sub suites {
    my ($self, @ciphers) = @_;

    @ciphers = map { "Crypt::$_" } (
	qw/Rijndael Twofish2 Twofish Blowfish IDEA DES_EDE3/,
	qw/DES TEA GOST Rijndael_PP Blowfish_PP DES_PP/,
    ) unless @ciphers;

    my @suites;

    foreach my $cipher (@ciphers) {
	no warnings;

	local $@;
	eval "use $cipher ()";
	next if $@;

	return $cipher if $#_;
	
	push @suites, $cipher;
    }

    warn "\n[Authen] cannot find a block cipher suite from:\n@ciphers\n".
         "secure connection will be disabled.\n" unless @suites;

    return @suites;
}

# adjust security levels
sub adjust {
    my ($self, $cipher_level, $auth_level, $keyid, $clientflag) = @_;

    $cipher_level ||= (CIPHER_NONE | CIPHER_BASIC | CIPHER_PGP);
    $auth_level   ||= (AUTH_NONE | AUTH_CRYPT | AUTH_PGP);

    if ($cipher_level & CIPHER_PGP or $auth_level & AUTH_PGP) {
    	if (!load_ok('GnuPG::Interface')) {
	    # pgp support broken, so...
	    $cipher_level &= ~CIPHER_PGP;
	    $auth_level   &= ~AUTH_PGP;
	}
	elsif ($keyid) {
	    unless ($Pubkey = `gpg --armor --export $keyid`) {
		$cipher_level &= ~CIPHER_PGP;
		$auth_level   &= ~AUTH_PGP;
	    }
	}
	elsif (!`gpg --version`) {
	    $cipher_level &= ~CIPHER_PGP;
	    $auth_level   &= ~AUTH_PGP;
	}
	else {
	    $cipher_level &= ~CIPHER_PGP unless $clientflag;
	    $auth_level   &= ~AUTH_PGP;
	}
    }

    if ($auth_level & AUTH_CRYPT) {
	unless (eval { crypt('  ', 'OurNet') } eq 'Ou6zLHZGLzASY') {
	    $auth_level &= ~AUTH_CRYPT;
	}
    }

    return ($cipher_level, $auth_level);
}

sub setpass {
    my ($self, $pass) = @_;

    $self->{gnupg}->passphrase($self->{pass} = $pass);
}

sub gpg_setup {
    my ($input, $output, $stderr) = ( 
	IO::Handle->new(),
	IO::Handle->new(),
	IO::Handle->new(),
    );

    my $handles = GnuPG::Handles->new( 
        stdin  => $input,
        stdout => $output,
        stderr => $stderr,
    );

    return ($input, $output, $stderr, $handles);
}

foreach my $method (qw/sign verify encrypt clearsign import_keys decrypt/) {
    my $subname = $method;
    no strict 'refs';
    $subname =~ s/_keys/_key/;

    *{__PACKAGE__."::$subname"} = sub {
	my $self = shift;

	if ($method eq 'decrypt' and not defined $self->{pass}) {
	    print "error: no passphrase for $self->{who}.\n";
	    exit;
	}

	my ($i, $o, $e, $h) = gpg_setup();

	my $pid = $self->{gnupg}->$method( 
	    handles => $h,
	    command_args => (
		($method eq 'clearsign') ? (
		    ['--default-key',  $self->{keyid}],
		) : ($method eq 'sign') ? (
		    ['--default-key',  $self->{keyid}],
		) : ( '' ),
	    )
	);

	if (@_) {
	    print $i @_;
	    close $i;
	}

	local $/;
	my $ret = ($method eq 'verify') ? <$e> : <$o>; # reading the output
	wait; # clean up the finished GnuPG process
	return $ret;
    };
}

# fix win32 behaviours because GnuPG::Interface will simply hang

if ($^O eq 'MSWin32') {

    *POSIX::STDERR_FILENO = sub { 2 };
    *POSIX::STDOUT_FILENO = sub { 1 };
    *POSIX::STDIN_FILENO = sub { 0 };

    eval <<'.';
	
no warnings 'redefine';

sub import_key {
    my ($self, $pubkey) = @_;
    
    open my $FH, '| gpg --import --quiet --batch';
    print $FH $pubkey;
    close $FH;
    
    return $pubkey;
}

sub encrypt {
    my ($self, $message) = @_;

    open my $FH, '>', 'encrypt' or die "$!";
    print $FH $message;
    close $FH;
    
    return if system("gpg --yes --encrypt --quiet --batch --always-trust --armor -r $self->{who} -o encrypt.gpg encrypt");
    
    local $/;
    open $FH, 'encrypt.gpg' or die "$!";
    $message = <$FH>;
    close $FH;

    unlink 'encrypt';
    unlink 'encrypt.gpg';
    
    return $message;
}

sub clearsign {
    my ($self, $message) = @_;

    open my $FH, '> encrypt' or die "$!";
    print $FH $message;
    close $FH;

    return if system(
	"gpg --yes --clearsign -u $self->{keyid} -o encrypt.gpg encrypt"
    );
    
    local $/;
    open $FH, 'encrypt.gpg' or die "$!";
    $message = <$FH>;
    close $FH;

    unlink 'encrypt';
    unlink 'encrypt.gpg';
    
    return $message;
}

.
}

1;

####################################################################### {{{
# The following section is a modified version of RPC::PlServer::Comm 
# code, with following added features:
#
# - Utilize ciphers with built-in BCB supports (Twofish2, Rijndael).
# - Out-of-band communication via callbacks.
# - Message queues allowing several packets be transferred at once.
#
# Because this makes the new server's behaviour incompatible from
# existing PlRPC's, I choose to fork a specific version just for
# OurNet::BBS's purpose. I'll notify the author once this modification
# proves to be stable and useful enough. 
#
# According to the Artistic License, the copyright information of 
# RPC::PlServer::Comm is acknowledged here:
# 
#   PlRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   Copyright (c) 1997,1998  Jochen Wiedmann
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
#
#           Email: joe@ispsoft.de
#           Phone: +49 7123 14887
#
# The source code PlRPC is very possibly on your computer right now,
# since OurNet::BBS::Authen depend on that library to run. Nevertheless,
# you may obtain the PlRPC source via the Bundle::PlRPC package from
# CPAN at http://www.cpan.org/.
#
####################################################################### }}}

package RPC::PlServer::Comm;

use strict;
no warnings 'deprecated';
no warnings 'redefine';

my ($WholeCipher, $Blocksize);
our (%Callback, @CallQueue);

use constant OUT_OF_BAND => 2 ** 31; # out-of-band size indicator

sub Read($) {{
    my $self = $_[0];
    my $socket = $self->{'socket'};
    my $result;

    my($encodedSize, $readSize, $blockSize);
    my $out_of_band = 0;

    $readSize = 4;
    $encodedSize = '';

    while ($readSize > 0) {
	my $result = $socket->read($encodedSize, $readSize,
				    length($encodedSize));
	if (!$result) {
	    return undef if defined($result);
	    die "Error while reading socket: $!" if $!;
	}
	$readSize -= $result;
    }

    $encodedSize = unpack("N", $encodedSize);

    # handles OOB (out of band) data
    if ($encodedSize & OUT_OF_BAND) {
	$encodedSize ^= OUT_OF_BAND;
	$out_of_band  = 1;
    }

    $readSize = $encodedSize;

    if ($self->{'cipher'}) {
	$blockSize = $Blocksize ||= $self->{'cipher'}->blocksize;
	if (my $addSize = ($encodedSize % $blockSize)) {
	    $readSize += ($blockSize - $addSize);
	}
    }

    my $msg = '';
    my $rs = $readSize;

    while ($rs > 0) {
	my $result = $socket->read($msg, $rs, length($msg));
	if (!$result) {
	    die "Unexpected EOF" if defined $result;
	    die "Error while reading socket: $!";
	}
	$rs -= $result;
    }

    if (my $cipher = $self->{'cipher'}) {
	if ($WholeCipher) {
	    $msg = $cipher->decrypt($msg);
	}
	elsif (index('Crypt::Rijndael Crypt::Twofish2 ', ref($cipher).' ')>-1) {
	    $WholeCipher = 1;
	    $msg = $cipher->decrypt($msg);
	}
	else {
	    my $encodedMsg = $msg;
	    $msg = '';
	    for (my $i = 0;  $i < $readSize;  $i += $blockSize) {
		$msg .= $cipher->decrypt(substr($encodedMsg, $i, $blockSize));
	    }
	}
	$msg = substr($msg, 0, $encodedSize) if $readSize != $encodedSize;
    }

    return Storable::thaw($msg) unless $out_of_band;

    # OOB calback code
    my $payload = Storable::thaw($msg);
    my $coderef = shift(@$payload);

    $coderef = $Callback{$coderef} or redo;

    print "out-of-band data received: $coderef->(@$payload)\n"
	if $OurNet::BBS::DEBUG;

    $coderef->(map {
	(ref($_) eq '__SPAWN__')
	    ? OurNet::BBS::Client::_spawn(@{$_}[2, 3])
	    : $_
    } @$payload) if UNIVERSAL::isa($coderef, 'CODE');
    
    redo; # resume to the next chunk
}}

use constant IsBroken => ($^V le v5.6.1);

sub Write ($$) {{
    my $self        = $_[0];
    my $out_of_band = scalar @CallQueue;
    my $msg         = $out_of_band ? shift(@CallQueue) : $_[1];
    my $socket      = $self->{'socket'};

    # works around broken GC code prior to v5.7.0.
    exit if IsBroken and (caller(1) eq 'RPC::PlClient::Object');

    my $encodedMsg = Storable::nfreeze($msg);
    my($encodedSize) = length($encodedMsg);

    if (my $cipher = $self->{'cipher'}) {
	my $size = $Blocksize ||= $cipher->blocksize;

	if (my $addSize = length($encodedMsg) % $size) {
	    $encodedMsg .= chr(0) x ($size - $addSize);
	}

	if ($WholeCipher) {
	    $encodedMsg = $cipher->encrypt($encodedMsg);
	}
	elsif (index('Crypt::Rijndael Crypt::Twofish2 ', ref($cipher).' ')>-1) {
	    $WholeCipher = 1;
	    $encodedMsg = $cipher->encrypt($encodedMsg);
	}
	else {
	    $msg = '';
	    for (my $i = 0;  $i < length($encodedMsg);  $i += $size) {
		$msg .= $cipher->encrypt(substr($encodedMsg, $i, $size));
	    }
	    $encodedMsg = $msg;
	}
    }

    if ($out_of_band) {
	print "Writting out-of-band data: $encodedSize bytes"
	    if $OurNet::BBS::DEBUG;

	$encodedSize += OUT_OF_BAND;
    }

    if ($socket and !$socket->print(pack("N", $encodedSize), $encodedMsg) ||
	!$socket->flush()) {
	die "Error while writing socket: $!" if $!;
    }

    redo if $out_of_band;
}}

1;
