use strict;
use warnings;
package OpusVL::SimpleCrypto;

# ABSTRACT: Very simple encryption methods.

use Moo;
use Crypt::Sodium;
use MIME::Base64;

our $VERSION = '0.008';

has key_string => (is => 'rw', lazy => 1, builder => '_build_key_string');
has key => (is => 'ro', lazy => 1, builder => '_build_key');
has deterministic_salt => (is => 'ro', lazy => 1, builder => '_build_deterministic_salt');
has deterministic_salt_string => (is => 'ro', lazy => 1, builder => '_build_deterministic_salt_string');

sub _build_deterministic_salt
{
    my $self = shift;
    die 'Must specify deterministic_salt or deterministic_salt_string' unless $self->deterministic_salt_string;
    return decode_base64($self->deterministic_salt_string);
}

sub _build_deterministic_salt_string
{
    my $self = shift;
    die 'Must specify deterministic_salt or deterministic_salt_string' unless $self->deterministic_salt;
    return encode_base64($self->deterministic_salt);
}

sub _build_key
{
    my $self = shift;
    die 'Must specify key or key_string' unless $self->key_string;
    return decode_base64($self->key_string);
}

sub _build_key_string
{
    my $self = shift;
    die 'Must specify key or key_string' unless $self->key;
    return encode_base64($self->key);
}

sub GenerateKey
{
    my $k = crypto_stream_key();
    my $salt = crypto_pwhash_salt();
    return OpusVL::SimpleCrypto->new({ key => $k, deterministic_salt => $salt });
}

sub encrypt
{
    my $self = shift;
    my $message = shift;
    my $n = crypto_stream_nonce();
    my $t = crypto_secretbox($message, $n, $self->key);
    return sprintf("%s:%s", encode_base64($n), encode_base64($t));
}

sub encrypt_deterministic
{
    my $self = shift;
    my $message = shift;
    my $salt = $self->deterministic_salt;
    my $n = crypto_pwhash_scrypt($message, $salt, crypto_stream_NONCEBYTES);
    my $t = crypto_secretbox($message, $n, $self->key);
    return sprintf("%s:%s", encode_base64($n), encode_base64($t));
}

sub decrypt
{
    my $self = shift;
    my $ciphertext = shift;
    my ($nonce, $cipher) = split /:/, $ciphertext;
    return crypto_secretbox_open(decode_base64($cipher), decode_base64($nonce), $self->key);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::SimpleCrypto - Very simple encryption methods.

=head1 VERSION

version 0.008

=head1 DESCRIPTION

Simple encrypt and decrypt methods.

    my $s = OpusVL::SimpleCrypto->GenerateKey;
    print $s->key_string, "\n";
    print $s->deterministic_salt_string, "\n";
    my $ct = $s->encrypt('Test');
    my $ct2 = $s->encrypt_deterministic('Test');


    my $crypto = OpusVL::SimpleCrypto->new({
        key_string => $key_string
        deterministic_salt_string => $deterministic_salt_string
    });
    my $message = $crypto->decrypt($ct);
    my $message2 = $crypto->decrypt($ct2);

This uses Crypt::Sodium under the hood to do simple symmetric (authenticated)
encryption and decryption.

This is for storing information encrypted in a database.  Make sure the key
is not in the database at the same time, otherwise this all becomes a bit
academic.

On debian derivative systems you probably need to install the libsodium-dev
package.

=head2 Choosing when to use encrypt or encrypt_deterministic.

If you are simply storing a value securely, and will simply retrieve it
to display it to the user, use encrypt.  It's more secure and will allow
the data to be stored as securely as a piece of software can.

If you need to look up an exact value, for example the value is a key
on the row, use encrypt_deterministic.  This means that you can
encrypt_deterministic the search value, and then search the database
without needing to decrypt any of the data.

If you want to search for text within an encrypted value, this library
won't cut it.  You'll need to look for searchable encryption.  This
normally involves indexes outside the main corpus that are also encrypted,
but having some determinism while hopefully not leaking too much
information.  It requires some serious engineering, and is generally
really hard to do right.

=head1 METHODS

=head2 GenerateKey

Create a key and salt and then return new OpusVL::SimpleCrypto initialized
with it.

Use the key_string method to get the key out in a format useful for storing.

You could run a quick command to print off some newly generated keys like this,

    perl -MOpusVL::SimpleCrypto -e '$k = OpusVL::SimpleCrypto->GenerateKey; printf("Key: %s\nSalt: %s\n", $k->key_string, $k->deterministic_salt_string)'

=head2 encrypt

Encrypt text.

The method should have these properties,

=over

=item * Encrpyting the same thing with the same key should not produce the same result.

=item * Encrypting a very similar value should not produce a similar ciphertext.

=item * The ciphertext is not malleable.

It should not be possible to modify it to generate a different plain text.

=back

=head2 encrypt_deterministic

This encrypts text like the L<encrypt> function, except that the
same thing encrypted with the same key will produce the same ciphertext.

This is useful when you want to search for the exact thing again.

The ciphertext produced by this will be decryptable by the same L<decrypt>
function.

If you encrypt 2 similar strings, i.e. '000001' and '000002' the
cipher text however should be very different.

The properties of this function should make searching for an exact
value possible, without needing to decrypt all the possible values.
It will not allow for partial searches of the encrypted values without
decrypting first.

This method allows more potential attacks than the data encrypted by
encrypt, so only use it where necessary.

This method has the following properties,

=over

=item * Encrpyting the same thing with the same key *should* produce the same result.

=item * Encrypting a very similar value should not produce a similar ciphertext.

=item * The ciphertext is not malleable.

It should not be possible to modify it to generate a different plain text.

=item * It is slower than the encrypt method.

=back

=head2 decrypt

Decrypt text.  Note that ciphertext that has been meddled with will
not decrypt, and the function will return undef instead.

=head1 ATTRIBUTES

Either set the string values, or the raw binary values, you don't need
to try setting all 4 at once.  Pick 2.

If you want to generate new info for a fresh configuration construct
an object with them populated with the GenerateKey constructor.

=head2 key_string

The key in a text friendly format.

=head2 key

The key in binary.

=head2 deterministic_salt_string

This is the salt used for deterministic encrpytion in a text friendly format.

This is required for the L<encrypt_deterministic> function.

=head2 deterministic_salt

This is the binary of the salt used for deterministic encrpytion.

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
