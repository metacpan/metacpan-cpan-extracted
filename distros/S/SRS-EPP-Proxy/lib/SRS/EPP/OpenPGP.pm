
package SRS::EPP::OpenPGP;
{
  $SRS::EPP::OpenPGP::VERSION = '0.22';
}

use 5.010;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use Crypt::OpenPGP;
use Crypt::OpenPGP::KeyRing;
use Carp;

with 'MooseX::Log::Log4perl';

BEGIN {
	class_type "Crypt::OpenPGP::KeyRing";
	class_type "Crypt::OpenPGP::KeyBlock";
	class_type "Crypt::OpenPGP::Certificate";
}

# Crypt::OpenPGP setup.
has 'pgp' =>
	is => "ro",
	isa => "Crypt::OpenPGP",
	lazy => 1,
	default => sub {
	my $self = shift;
	Crypt::OpenPGP->new(
		(
			$self->_has_secret_keyring
			? (SecRing => $self->secret_keyring)
			: ()
		),
		(
			$self->_has_public_keyring
			? (PubRing => $self->public_keyring)
			: ()
		),
	);
	},
	;

coerce "Crypt::OpenPGP::KeyRing"
	=> from "Str"
	=> via {
	Crypt::OpenPGP::KeyRing->new(
		Filename => $_,
	);
	};

has 'secret_keyring' =>
	is => "ro",
	isa => "Crypt::OpenPGP::KeyRing",
	lazy => 1,
	predicate => "_has_secret_keyring",
	coerce => 1,
	default => sub {
	my $self = shift;
	$self->pgp->{cfg}->get("SecRing");
	},
	;
has 'public_keyring' =>
	is => "ro",
	isa => "Crypt::OpenPGP::KeyRing",
	lazy => 1,
	predicate => "_has_public_keyring",
	coerce => 1,
	default => sub {
	my $self = shift;
	$self->pgp->{cfg}->get("PubRing");
	},
	;


# specifying the default signing/encryption key

BEGIN {
	subtype "SRS::EPP::OpenPGP::key_id"
		=> as "Str",
		=> where {
		m{^(?:0x)?(?:(?:[0-9a-f]{4}\s?){2}){1,2}$}i;
		};
}

has 'uid' =>
	is => "rw",
	isa => "SRS::EPP::OpenPGP::key_id",
	trigger => sub {
	my $self = shift;
	my $uid = shift;
	$self->default_signing_key(
		$self->find_signing_key($uid)
	);
	$self->default_encrypting_key(
		$self->find_signing_key($uid)
	);
	}
	;

has 'passphrase' =>
	is => "rw",
	isa => "Str",
	;

sub unlock_cert {
    my $self = shift;
    
    my ( $cert ) = pos_validated_list(
        \@_,
        { isa => 'Crypt::OpenPGP::Certificate' },
    );    
    
	return unless $cert->is_protected;

	return if $self->passphrase and
			$cert->unlock($self->passphrase);

	my $key_id = $cert->fingerprint_hex;
	require Scriptalicious;

	unless (-t STDIN) {
		$self->logger->fatal("no terminal");
		die "no terminal";
	}

	$self->passphrase(
		Scriptalicious::prompt_passwd(
			"Enter passphrase for PGP cert $key_id:"
		),
	);
	print "\n";  # workaround bug in Scriptalicious..

	return $self->unlock_cert($cert);
}

has 'default_signing_key' => (
	is => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		my $sec_ring = $self->secret_keyring;
		my $kb = $self->get_sec_key_block
			or die "no secret key block";
		my $cert = $kb->signing_key
			or croak "Invalid default secret key; specify pgp_keyid in config";
		$self->unlock_cert($cert);
		$cert->uid($kb->primary_uid);
		$cert;
	},
);

has 'default_encrypting_key' =>
	is => "rw",
	;

sub find_signing_key {
    my $self = shift;
    
    my ( $key_id ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::OpenPGP::key_id' },
    );        
    
	my $kb = $self->get_sec_key_block($key_id) or return;
	my $cert = $kb->signing_key
		or croak "Invalid signing key $key_id";
	$self->unlock_cert($cert);
	$cert->uid($kb->primary_uid);
	return $cert;
}

sub find_encrypting_key {
    my $self = shift;
    
    my ( $key_id ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::OpenPGP::key_id' },
    );
    
	my $kb = $self->get_sec_key_block($key_id) or return;
	my $cert = $kb->encrypting_key
		or croak "Invalid encrypting key $key_id";
	$self->unlock_cert($cert);
	$cert->uid($kb->primary_uid);
	return $cert;
}

sub get_sec_key_block {
    my $self = shift;
    
    my ( $key_id ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::OpenPGP::key_id', optional => 1 },
    );    
    
	my $sec_ring = $self->secret_keyring;

	my $func = sub{$sec_ring->find_keyblock_by_index(@_)};
	my $param = -1;
	my $label = "default";
	if ($key_id) {
		$key_id =~ s{^0x}{};
		$func = sub{$sec_ring->find_keyblock_by_keyid(@_)};
		$param = pack("H*", $key_id);
		$label = $key_id;
	}

	my $kb = $func->($param)
		or croak "Can't find keyblock ($label): " . $sec_ring->errstr;
	return $kb;
}

sub get_pub_key_block {
    my $self = shift;
    
    my ( $key_id ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::OpenPGP::key_id', optional => 1 },
    );
    
	my $pub_ring = $self->public_keyring;
	$key_id =~ s{^0x}{};
	my $kb = $key_id
		? $pub_ring->find_keyblock_by_keyid( pack("H*", $key_id) )
		: $pub_ring->find_keyblock_by_index(-1)
		or croak "Can't find keyblock ("
		.($key_id ? $key_id : "default")
		."): " . $pub_ring->errstr;
	return $kb;
}

sub get_cert_from_key_text{
    my $self = shift;
    
    my ( $key_text ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );        
    
	my $kr = new Crypt::OpenPGP::KeyRing(Data => $key_text)
		or return;
	my $kb = $kr->find_keyblock_by_index(-1)
		or return;
	my $cert = $kb->signing_key
		or return;
	$cert->uid($kb->primary_uid);
	$cert;
}

use Encode;
use utf8;

sub byte_string {
	if ( utf8::is_utf8($_[0]) ) {
		encode("utf8", $_[0]);
	}
	else {
		$_[0];
	}
}

sub verify_detached {
    my $self = shift;
    
    my ( $data, $signature, $cert, $key_text ) = validated_list(
        \@_,
        data => { isa => 'Str' },
        signature => { isa => 'Str' },
        cert => { optional => 1 },
        key_text => { optional => 1 },
    );      
    
	if ($key_text) {
		$cert ||= $self->get_cert_from_key_text($key_text);
	}
	my $pgp = $self->pgp;
	my $res = $pgp->verify(
		Data => byte_string($data),
		Signature => $signature,
		( $cert ? (Key => $cert) : () ),
	);
	if ($res) {
		my $res_neg = $pgp->verify(
			Data => "xx.$$.".rand(3),
			Signature => $signature,
			( $cert ? (Key => $cert) : () ),
		);
		if ( $res and $res_neg ) {

			# a full doc was passed in as a signature...
			$res = 0;
		}
	}
	warn $pgp->errstr if !$res && $pgp->errstr;
	return $res;
}

sub detached_sign {
    my $self = shift;
    
    my ( $data, $key, $passphrase ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { optional => 1 },
        { optional => 1 },        
    );     
    
    
	$key ||= $self->default_signing_key;
	my $pgp = $self->pgp;
	my $signature = $pgp->sign(
		Data => byte_string($data),
		Detach => 1,
		Armour => 1,
		Digest => "SHA1",
		Passphrase => $passphrase//"",
		Key => $key,
	);

	carp "Signing attempt failed: ", $pgp->errstr() unless $signature;
	return $signature;
}

1;
