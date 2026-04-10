package Net::Nostr::Key;

use strictures 2;

use Carp qw(croak);
use Crypt::PK::ECC;
use Crypt::PK::ECC::Schnorr;
use Digest::SHA qw(sha256_hex);
use Net::Nostr::Event;

use Class::Tiny qw(_cryptpkecc);

sub new {
    my ($class, %args) = @_;
    my %known_args = map { $_ => 1 } qw(privkey pubkey);
    my @unknown = grep { !exists $known_args{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    croak "privkey and pubkey are mutually exclusive"
        if defined $args{privkey} && defined $args{pubkey};
    my $self = bless {}, $class;
    my @key_arg = defined $args{privkey} ? ($args{privkey})
                : defined $args{pubkey}  ? ($args{pubkey})
                :                          ();
    $self->_cryptpkecc(Crypt::PK::ECC->new(@key_arg));
    $self->_cryptpkecc->generate_key('secp256k1') unless $self->pubkey_loaded;
    return $self;
}

sub constructor_keys { qw(privkey pubkey) }

sub from_mnemonic {
    my ($class, $mnemonic, %args) = @_;
    croak "from_mnemonic requires a mnemonic" unless defined $mnemonic;

    require Bitcoin::Crypto::Key::ExtPrivate;
    require Bitcoin::BIP39;

    Bitcoin::BIP39::bip39_mnemonic_to_entropy(mnemonic => $mnemonic);

    my $account = $args{account} // 0;
    my $path = "m/44'/1237'/${account}'/0/0";

    my $seed = Bitcoin::Crypto::Key::ExtPrivate->from_mnemonic($mnemonic);
    my $derived = $seed->derive_key($path);
    my $privkey_bytes = $derived->raw_key("private");

    my $pk = Crypt::PK::ECC->new;
    $pk->import_key_raw($privkey_bytes, 'secp256k1');

    my $self = bless {}, $class;
    $self->_cryptpkecc($pk);
    return $self;
}

sub generate_mnemonic {
    my ($class, %args) = @_;
    require Bitcoin::BIP39;
    my $bits = $args{bits} // 128;
    my $result = Bitcoin::BIP39::gen_bip39_mnemonic(bits => $bits);
    return ref $result eq 'HASH' ? $result->{mnemonic} : $result;
}

sub schnorr_sign {
    my ($self, $msg) = @_;
    my $sig = Crypt::PK::ECC::Schnorr->new(\$self->privkey_der)->sign_message($msg);
    return $sig;
}

sub privkey_loaded {
    my ($self) = @_;
    my $is_private = $self->_cryptpkecc->is_private;
    return 1 if $is_private;
    return 0;
}

sub pubkey_loaded {
    my ($self) = @_;
    my $is_private = $self->_cryptpkecc->is_private;
    return 1 if defined $is_private;
    return 0;
}

sub pubkey_der {
    my ($self) = @_;
    my $der = $self->_cryptpkecc->export_key_der('public');
    return $der;
}

sub privkey_der {
    my ($self) = @_;
    my $der = $self->_cryptpkecc->export_key_der('private');
    return $der;
}

sub pubkey_pem {
    my ($self) = @_;
    my $pem = $self->_cryptpkecc->export_key_pem('public');
    return $pem;
}

sub privkey_pem {
    my ($self) = @_;
    my $pem = $self->_cryptpkecc->export_key_pem('private');
    return $pem;
}

sub pubkey_raw {
    my ($self) = @_;
    my $raw = $self->_cryptpkecc->export_key_raw('public');
    return $raw;
}

sub privkey_raw {
    my ($self) = @_;
    my $raw = $self->_cryptpkecc->export_key_raw('private');
    return $raw;
}

sub pubkey_hex {
    my ($self) = @_;
    my $raw = $self->pubkey_raw;
    my $x = substr($raw, 1, 32); # skip 04 prefix, take x-only (BIP-340)
    return unpack 'H*', $x;
}

sub privkey_hex {
    my ($self) = @_;
    my $hex = unpack 'H*', $self->privkey_raw;
    return $hex;
}

sub pubkey_npub {
    my ($self) = @_;
    require Net::Nostr::Bech32;
    return Net::Nostr::Bech32::encode_npub($self->pubkey_hex);
}

sub privkey_nsec {
    my ($self) = @_;
    require Net::Nostr::Bech32;
    return Net::Nostr::Bech32::encode_nsec($self->privkey_hex);
}

sub save_privkey {
    my ($self, $path) = @_;
    croak "no private key loaded" unless $self->privkey_loaded;
    require Fcntl;
    sysopen my $fh, $path, Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_TRUNC(), 0600
        or croak "cannot open $path: $!";
    binmode $fh;
    print $fh $self->privkey_pem;
    close $fh;
}

sub save_pubkey {
    my ($self, $path) = @_;
    open my $fh, '>', $path or croak "cannot open $path: $!";
    binmode $fh;
    print $fh $self->pubkey_pem;
    close $fh;
}

sub sign_event {
    my ($self, $event) = @_;
    croak "pubkey does not match signing key"
        unless $event->pubkey eq $self->pubkey_hex;
    my $expected_id = sha256_hex($event->json_serialize);
    croak "id does not match event body"
        unless $event->id eq $expected_id;
    my $sig_raw = $self->schnorr_sign($event->id);
    my $sig_hex = unpack 'H*', $sig_raw;
    $event->sig($sig_hex);
    return $sig_hex;
}

sub create_event {
    my ($self, %args) = @_;
    $args{pubkey} = $self->pubkey_hex;
    my $event = Net::Nostr::Event->new(%args);
    $self->sign_event($event);
    return $event;
}

1;

__END__

=head1 NAME

Net::Nostr::Key - Secp256k1 keypair management for Nostr

=head1 SYNOPSIS

    use Net::Nostr::Key;

    # Generate a new keypair
    my $key = Net::Nostr::Key->new;
    say $key->pubkey_npub;   # npub1...
    say $key->privkey_nsec;  # nsec1...
    say $key->pubkey_hex;    # 64-char hex (x-only, BIP-340)
    say $key->privkey_hex;   # 64-char hex

    # Save and load from file
    $key->save_privkey('my_key.pem');
    my $key = Net::Nostr::Key->new(privkey => 'my_key.pem');

    # Create and sign an event
    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);

    # Load from DER data
    my $key = Net::Nostr::Key->new(privkey => \$der_bytes);
    my $key = Net::Nostr::Key->new(pubkey  => \$der_bytes);

    # Derive from mnemonic seed phrase (NIP-06)
    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);

=head1 DESCRIPTION

Manages secp256k1 keypairs for the Nostr protocol. Supports key generation,
import/export in multiple formats (hex, raw, DER, PEM, NIP-19 bech32),
file-based key storage, BIP-340 Schnorr signatures, and
L<NIP-06|https://github.com/nostr-protocol/nips/blob/master/06.md> key
derivation from BIP-39 mnemonic seed phrases.

=head1 CLASS METHODS

=head2 from_mnemonic

    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);

Derives a secp256k1 keypair from a BIP-39 mnemonic seed phrase using the
NIP-06 derivation path C<m/44'/1237'/E<lt>accountE<gt>'/0/0>. The C<account>
defaults to C<0>.

    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    say $key->privkey_hex;   # 7f7ff03d...
    say $key->pubkey_npub;   # npub1zut...

A basic client can use the default account C<0> to derive a single key.
For more advanced use-cases, increment C<account> to generate practically
infinite keys from the same mnemonic:

    my $key0 = Net::Nostr::Key->from_mnemonic($mnemonic);
    my $key1 = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);

Croaks if the mnemonic is invalid.

=head2 generate_mnemonic

    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my $mnemonic = Net::Nostr::Key->generate_mnemonic(bits => 256);

Generates a new BIP-39 mnemonic seed phrase. The C<bits> parameter controls
the entropy size: C<128> (default) produces 12 words, C<256> produces
24 words.

    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    say $key->pubkey_npub;

=head1 CONSTRUCTOR

=head2 new

    my $key = Net::Nostr::Key->new;
    my $key = Net::Nostr::Key->new(privkey => \$der_bytes);
    my $key = Net::Nostr::Key->new(pubkey  => \$der_bytes);
    my $key = Net::Nostr::Key->new(privkey => 'my_key.pem');

Without arguments, generates a new secp256k1 keypair. Pass C<privkey> or
C<pubkey> as a scalar reference to key data (DER or PEM), or as a filename
string to load from a file (PEM or DER format). C<privkey> and C<pubkey>
are mutually exclusive. When only a public key is loaded, signing operations
will fail. Croaks on unknown arguments or if both C<privkey> and C<pubkey>
are provided.

    # Save a key to a file and load it back
    $key->save_privkey('my_key.pem');
    my $key = Net::Nostr::Key->new(privkey => 'my_key.pem');

=head1 METHODS

=head2 schnorr_sign

    my $sig = $key->schnorr_sign($message);  # 64 raw bytes

Signs the given message using BIP-340 Schnorr signatures. Returns the
raw 64-byte signature. Requires a private key to be loaded.

    my $key = Net::Nostr::Key->new;
    my $sig = $key->schnorr_sign('hello');
    say length($sig);  # 64

=head2 privkey_loaded

    my $bool = $key->privkey_loaded;

Returns true if a private key is loaded (i.e. signing is possible).

=head2 pubkey_loaded

    my $bool = $key->pubkey_loaded;

Returns true if any key material is loaded (public or private).

    my $key = Net::Nostr::Key->new(pubkey => \$der);
    say $key->pubkey_loaded;   # 1
    say $key->privkey_loaded;  # 0

=head2 pubkey_hex

    my $hex = $key->pubkey_hex;  # 64-char lowercase hex

Returns the x-only public key as a 64-character hex string, suitable for
use as a Nostr pubkey (BIP-340 format).

=head2 privkey_hex

    my $hex = $key->privkey_hex;  # 64-char lowercase hex

Returns the private key as a 64-character hex string.

=head2 pubkey_npub

    my $npub = $key->pubkey_npub;  # 'npub1...'

Returns the public key as a NIP-19 bech32-encoded C<npub> string.

    my $key = Net::Nostr::Key->new;
    say $key->pubkey_npub;  # npub1...

=head2 privkey_nsec

    my $nsec = $key->privkey_nsec;  # 'nsec1...'

Returns the private key as a NIP-19 bech32-encoded C<nsec> string.

    my $key = Net::Nostr::Key->new;
    say $key->privkey_nsec;  # nsec1...

=head2 pubkey_raw

    my $raw = $key->pubkey_raw;  # 65 bytes (04 || x || y)

Returns the uncompressed public key as raw bytes (65 bytes with C<04> prefix).

=head2 privkey_raw

    my $raw = $key->privkey_raw;  # 32 bytes

Returns the private key as 32 raw bytes.

=head2 pubkey_der

    my $der = $key->pubkey_der;

Returns the public key in DER-encoded format. Can be passed to a new
Key constructor:

    my $key2 = Net::Nostr::Key->new(pubkey => \$key->pubkey_der);

=head2 privkey_der

    my $der = $key->privkey_der;

Returns the private key in DER-encoded format.

    my $key2 = Net::Nostr::Key->new(privkey => \$key->privkey_der);

=head2 pubkey_pem

    my $pem = $key->pubkey_pem;

Returns the public key in PEM-encoded format (Base64 with header/footer).

    say $key->pubkey_pem;
    # -----BEGIN PUBLIC KEY-----
    # ...
    # -----END PUBLIC KEY-----

=head2 privkey_pem

    my $pem = $key->privkey_pem;

Returns the private key in PEM-encoded format.

=head2 save_privkey

    $key->save_privkey('my_key.pem');

Saves the private key to the given file path in PEM format with file
mode C<0600> (owner read/write only). Croaks if no private key is loaded.

    my $key = Net::Nostr::Key->new;
    $key->save_privkey('my_key.pem');

    # Load it back later
    my $same_key = Net::Nostr::Key->new(privkey => 'my_key.pem');

=head2 save_pubkey

    $key->save_pubkey('my_pubkey.pem');

Saves the public key to the given file path in PEM format.

    my $key = Net::Nostr::Key->new;
    $key->save_pubkey('my_pubkey.pem');

    my $pub_only = Net::Nostr::Key->new(pubkey => 'my_pubkey.pem');

=head2 sign_event

    my $sig_hex = $key->sign_event($event);

Verifies that C<< $event->pubkey >> matches this key and that the stored
ID matches the event body, then signs with BIP-340 Schnorr and sets the
event's C<sig> field. Croaks if the pubkey does not match or the ID has
been tampered with. Any existing signature is unconditionally replaced.
Returns the signature as a 128-character hex string.

    my $event = Net::Nostr::Event->new(
        pubkey => $key->pubkey_hex, kind => 1,
        content => 'hello', tags => [],
    );
    $key->sign_event($event);
    say $event->sig;  # 128-char hex

=head2 create_event

    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);

Convenience method that creates a new L<Net::Nostr::Event> with the
key's public key, signs it, and returns the signed event.

    my $event = $key->create_event(
        kind    => 1,
        content => 'hello world',
        tags    => [['t', 'nostr']],
    );
    say $event->id;   # set
    say $event->sig;  # set

=head2 constructor_keys

    my @keys = Net::Nostr::Key->constructor_keys;  # ('privkey', 'pubkey')

Returns the list of valid constructor argument names. Used internally
by L<Net::Nostr> to extract key-related arguments.

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-06|https://github.com/nostr-protocol/nips/blob/master/06.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
