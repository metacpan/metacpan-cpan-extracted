# NAME

Noise - Pure Perl implementation of the Noise Protocol Framework

# SYNOPSIS

```perl
use Noise;

# Initialize state for Noise_XX_25519_ChaChaPoly_SHA256
my $alice = Noise->new( );
$alice->initialize_state( );

# Handshake Pattern: XX

# Msg 1: Alice -> Bob (e)
my $msg1 = $alice->write_message( 'e', '' ); # payload is optional

# Msg 2: Bob -> Alice (e, ee, s, es)
my ( $payload, $error ) = $alice->read_message( 'e, ee, s, es', $msg2 );

# ... after handshake ...
my ( $send_key, $recv_key ) = $alice->split_for_transport( );
```

# DESCRIPTION

`Noise` implements the Noise Protocol Framework, a modern cryptographic construction for building high-performance,
secure  communications protocols.

This implementation provides the foundational SymmetricState and CipherState logic, as well as helper methods for
executing handshake  patterns like XX.

# Architecture

## SymmetricState

Manages the chaining key (`ck`) and the handshake hash (`h`). It ensures that every message sent or received
contributes to the overall  cryptographic transcript.

## CipherState

Handles the symmetric encryption (ChaCha20-Poly1305) and nonce management. Nonces are automatically incremented and
reset according to the spec.

# METHODS

## `new(%params )`

Constructor.

Expected parameter:

- `prologue`: Optional initial data to be hashed into the state.

## `initialize_state( $protocol_name )`

Sets up the state machine for a specific protocol. Defaults to `Noise_XX_25519_ChaChaPoly_SHA256`.

## `mix_hash( $data )`

Incorporates `$data` into the handshake hash.

## `mix_key( $ikm )`

Derives a new chaining key and symmetric key from the provided input keying material (typically a DH shared secret).

## `encrypt_and_hash( $plaintext )`

Writes a payload to the handshake state. This method encrypts the plaintext using the current symmetric key and
incorporates the resulting ciphertext into the handshake hash. This ensures that the transcript is kept in
synchronization between parties.

## `decrypt_and_hash( $ciphertext )`

Reads a payload from the handshake state. This method decrypts the ciphertext, verifies the MAC tag, and incorporates
the ciphertext into the handshake hash. Dies if decryption fails.

## `split_for_transport( )`

Finalizes the handshake and returns two 32-byte keys for secure communication.

# Handshake Patterns

While this module provides low-level primitives, it is recommended to use higher-level wrappers (like
[Net::Libp2p::Noise](https://metacpan.org/pod/Net%3A%3ALibp2p%3A%3ANoise)) for specific application integrations.

# SEE ALSO

[Noise::Stream](https://metacpan.org/pod/Noise%3A%3AStream), [https://noiseprotocol.org/](https://noiseprotocol.org/)

[Crypt::Noise](https://metacpan.org/pod/Crypt%3A%3ANoise) is an earlier implementation.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
