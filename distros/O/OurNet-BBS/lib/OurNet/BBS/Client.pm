# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Client.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 3958 $ $DateTime: 2003/01/28 02:21:52 $

package OurNet::BBS::Client;

use strict;
no warnings 'deprecated';
use OurNet::BBS::Base;

# Declaration {{{

our ($AUTOLOAD, $Ego, $Port, $NoCache);

use overload (
    '""'   => sub { overload::AddrRef($_[0]) },
    '<=>'  => sub { "$_[0]" cmp "$_[1]" },
    'cmp'  => sub { "$_[0]" cmp "$_[1]" },
    'bool' => sub { 1 },
    '0+'   => sub { 0 },
    '&{}'  => sub {
	my $self = ${$_[0]};
	$Ego = $self->[0];
	return sub {
	    $AUTOLOAD = 'OurNet::BBS::Client::EXECUTE';
	    EXECUTE(bless(\[$self, 'CODE_'], __PACKAGE__), @_);
	};
    },
    map {
	my $type = $_; 
	( SIGILS->[$type].'{}' => sub {
	    my $self = ${$_[0]};
	    $Ego = $self->[0];
	    return $self->[$type];
	} );
    } ( HASH .. ARRAY ),
);

use RPC::PlClient;
use Digest::MD5 qw/md5/;
use OurNet::BBS::Authen;

use enum qw/id remote_ref optree/;
use enum qw/BITMASK:CIPHER_ NONE BASIC PGP/;
use enum qw/BITMASK:AUTH_   NONE CRYPT PGP/;

sub UNTIE() {}
sub DESTROY() {}

# }}}

# Initialization {{{

$Port = 7979;

my $OP = $OurNet::BBS::Authen::OP;
my (%Cache, @delegators, @arguments);

tie my %obj  => __PACKAGE__, 'HASH_';
tie my @obj  => __PACKAGE__, 'ARRAY_';
tie my $code => __PACKAGE__, 'CODE_'; # XXX: not working
tie my $glob => __PACKAGE__, 'GLOB_'; # XXX: not working

sub TIEHASH   { bless(\[$_[1]], $_[0]) }
sub TIEARRAY  { bless(\[$_[1]], $_[0]) }
sub TIESCALAR { bless(\[$_[1]], $_[0]) }

use constant IsWin32 => ($^O eq 'MSWin32');

if (IsWin32 and not Win32::IsWinNT()) {
    require Net::Daemon::Log;

    no strict 'refs';
    no warnings 'redefine';

    *{'Net::Daemon::Log'}	= sub { return };
    *{'Net::Daemon::Log::Log'}	= sub { return };
}

# }}}

sub _spawn {
    # spawn (optree_id)
    my $self = [ $Ego->[id], @_ ];

    show("SPAWN: @_\n");

    # warning: one-arg bless!
    return bless(\[$self, \%obj, \@obj, \$code, \$glob, 'OBJECT_']);
}

sub new {
    my $class    = shift;
    my $peeraddr = shift;
    my $peerport = shift || $Port;
    my @args = (
	peeraddr    => $peeraddr,
	peerport    => $peerport,
	application => 'OurNet::BBS::Server',
	version     => $OurNet::BBS::Authen::VERSION,
    );

    my $id = @delegators; # 1 more than max
    $arguments[$id] = [\@args, @_];

    return $class->generate($id);
}

sub generate {
    my ($class, $id) = @_;
    my $self = []; $self->[id] = $id;

    if ($delegators[$id]) {
	delete $delegators[$id]{client};
	$delegators[$id]->DESTROY;
    }

    $delegators[$id] = RPC::PlClient->new(
	@{$arguments[$id][0]}
    )->ClientObject('__', 'spawn');

    my $obj = bless(\[$self, \%obj, \@obj, \$code, \$glob, 'OBJECT_'], $class);
    return $obj->init(@{$arguments[$id]}[1 .. $#{$arguments[$id]}]);
}

## Handshake Phase ####################################################
# spawn a handle and get server's accepted modes. {{{

sub init {
    my ($obj, $keyid, $user, $pass, $cipher_level, $auth_level) = @_; 
    my $self = ${$obj}->[0];

    my $client = $delegators[$self->[id]];

    unless ($OurNet::BBS::BYPASS_NEGOTIATION) {
	($cipher_level, $auth_level) = $client->handshake(
	    OurNet::BBS::Authen->adjust(
		$cipher_level, $auth_level, $keyid, 1
	    )
	) or print "[Client] initialization failed.\n" and die;

	my ($status, $auth) = negotiate_cipher($client, $cipher_level)
	    or print "[Client] cipher negotiation failed.\n" and die;

	negotiate_auth($client, $auth_level, $auth, $keyid, $user, $pass)
	    or print "[Client] authentication failed.\n" and die;

	$self->[remote_ref] = negotiate_locate($client)
	    or print "[Client] object location failed.\n" and die;
    }

    show("done!\n");

    return $obj; 
}

sub negotiate_locate {
    my $client = shift;

    return $client->locate(@_);
}

sub make_auth {
    my ($keyid, $pubkey) = @_;

    my $auth = OurNet::BBS::Authen->new($keyid) or return;
    $auth->import_key($pubkey);

    return $auth;
}

# }}}

## Cipher Phase #######################################################
# gets supported cipher suites and (optionally) server's public key {{{

sub negotiate_cipher {
    my ($client, $mode, $auth) = @_;

    my $cipher = OurNet::BBS::Authen->suites($client->get_suites)
	if $mode & (CIPHER_BASIC | CIPHER_PGP);

    show("[Client] agreed on cipher: $cipher ") if $cipher;

    if ($cipher and $mode & CIPHER_PGP) {
	$auth = make_auth($client->get_pubkey);

	if ($auth and cipher_pgp($client, $cipher, $auth)) {
	    show("in secure mode.\n");
	    return(CIPHER_PGP, $auth);
	}
    }

    if ($cipher and $mode & CIPHER_BASIC) {
	if (cipher_basic($client, $cipher)) {
	    show("in insecure mode.\n");
	    return(CIPHER_BASIC, $auth);
	}
    }

    if ($mode & CIPHER_NONE and cipher_none($client)) {
	show("[Client] warning: using plaintext communication.\n");
	return(CIPHER_NONE, $auth);
    }

    show("failed!\n");
    return;
}

sub cipher_pgp {
    my ($client, $cipher, $auth) = @_;

    my $keysize = $cipher->keysize || (
	$cipher eq 'Crypt::Blowfish' ? 56 : 8
    );

    # make session key
    my $session_key = md5(rand);
    $session_key .= md5(rand) until length($session_key) >= $keysize;
    $session_key = substr($session_key, 0, $keysize);

    my $authcrypt = $auth->encrypt($session_key) or return; # encrypt it
    $client->cipher_pgp($cipher, $authcrypt) or return;	    # send it back

    $client->{client}{cipher} = $cipher->new($session_key);

    return $auth;
}

sub cipher_basic {
    my ($client, $cipher) = @_;
    my ($status, $session) = $client->cipher_basic($cipher) or return;

    return ($client->{client}{cipher} = $cipher->new($session));
}

sub cipher_none {
    my ($client) = @_;
    return $client->cipher_none;
}

# }}}

## Auth Phase #########################################################
# log in by trying each mutually acceptable authentication schemes {{{

sub negotiate_auth {
    my ($client, $mode, $auth, $keyid, $user, $pass) = @_;

    # Authentication Negotiation
    show("[Client] begin authentication...");

    if ($mode & AUTH_PGP and $auth ||= make_auth($client->get_pubkey)) {
	# public key authentication
	show("trying pubkey...");
	return AUTH_PGP if auth_pgp(
	    $client, $auth, $keyid, $user, $pass
	);
    }

    if ($mode & AUTH_CRYPT and $user) {
	# crypt-based authentication
	show("trying crypt...");
	return AUTH_CRYPT if auth_crypt($client, $user, $pass);
    }

    if ($mode & AUTH_NONE and $client->auth_none($user)) {
	# no authentication at all
	show("fallback to none...");
	return AUTH_NONE;
    }

    show("failed!\n");
    return;
}

sub auth_pgp {
    my ($client, $auth, $keyid, $login, $passphrase) = @_;
    return unless $keyid and $login and defined $passphrase;

    $auth->{keyid} = $keyid;
    $auth->setpass($passphrase);

    my $challenge = $client->auth_pgp($login);

    if ($challenge eq $OP->{STATUS_NO_USER}) {
	show('no such user! ');
	return;
    }
    elsif ($challenge eq $OP->{STATUS_NO_PUBKEY}) {
	show('no public key info! ');
	return;
    }
    elsif ($challenge eq $OP->{STATUS_OK}) {
	show("challenge($challenge)");
	$challenge = $client->set_pubkey($auth->export_key);
    }

    if ($challenge eq $OP->{STATUS_BAD_PUBKEY}) {
	show('public key mismatch! ');
	return;
    }

    my $signature = $auth->clearsign($challenge)
	or (show('cannot make signature! ') and return);

    if ($client->set_sign($signature) eq $OP->{STATUS_BAD_SIGNATURE}) {
	show('signature rejected! ');
	return;
    }

    return 1;
}

sub auth_crypt {
    my ($client, $user, $pass) = @_;
    my ($status, $salt) = $client->auth_crypt($user) or return;

    if ($status eq $OP->{STATUS_NO_USER}) {
	show('no such user! ');
	return;
    }

    return (
	$client->set_crypted(crypt($pass, $salt)) eq $OP->{STATUS_ACCEPTED}
    );
}

sub auth_none {
    my ($client) = @_;
    return $client->auth_none;
}

sub quit {
    foreach my $client (@delegators) {
	$client->quit if $client;
    }

    undef @delegators;
}

sub show {
    no warnings 'once';
    print $_[0] if $OurNet::BBS::DEBUG;
}

sub register_callback {
    my $coderef = shift;
    my $proxy   = bless(\"$coderef", '__CODE__');

    show("$coderef registered for callback\n");

    $RPC::PlServer::Comm::Callback{"$coderef"} = $coderef;
    return $proxy;
}

# }}}

## Connected ##########################################################
# do the real job via AUTOLOAD passing and ArrayHashMonster magic {{{

sub AUTOLOAD {
    my ($ego, $op);

    no strict 'refs';
    return unless $delegators[$Ego->[id]];

    my $action = substr($AUTOLOAD, (
	(rindex($AUTOLOAD, ':') + 1) || return
    ));

    # install a closure-based handler for future use instead of AUTOLOAD
*{$AUTOLOAD} = sub {
    no warnings 'uninitialized';

    my ($self, $op) = @{${+shift}}[0, -1];

    local $Ego = $self if ($op eq 'OBJECT_');

    $op .= $action;

    my @result;
    
    do { eval {
	undef $@;
	@result = $delegators[$Ego->[id]]->__(
	    $OP->{$op} || $op, $Ego->[optree], map { 
		ref($_) eq __PACKAGE__ 
		    ? bless(\(${$_}->[0][optree]), '__') :
		ref($_) eq 'CODE'
		    ? register_callback($_) 
		: $_;
	    } @_
	);
    } } while (
	$@ and $@ =~ /^Error while reading socket:/ and
	__PACKAGE__->generate($Ego->[id])
    );

    die $@ if $@;

    if (@result == 4 and !$result[0] and my $opcode = $result[1]) {
        return ($NoCache ? _spawn(@result[2, 3])
			 : ($Cache{$result[2]} ||= _spawn(@result[2, 3])))
	    if $OP->{$opcode} eq 'OBJECT_SPAWN';

	return @result if $OP->{$opcode} eq 'STATUS_IGNORED';

        die "@result[2, 3] [$OP->{$opcode}]\n";
    }

#   print ("<==:  ".(wantarray ? "@result" : $result[0]), "\n");
    return wantarray ? @result : $result[0];
} unless exists(&{$AUTOLOAD});

    goto &{$AUTOLOAD};
}

# }}}

1;
