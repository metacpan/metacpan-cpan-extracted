package PAGI::FastAPI::BotProtection::ProofOfWork;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

use Digest::SHA qw(sha256_hex hmac_sha256_hex);
use Time::HiRes  qw(time);

class PAGI::FastAPI::BotProtection::ProofOfWork {
    field $difficulty :param = 3;                         # Number of required leading zeros in SHA-256 hash
    field $secret     :param = 'change_me_in_production'; # HMAC secret seed to prevent challenge forgery
    field $ttl        :param = 300;                       # Challenge validity duration in seconds

    # Fields are joined/split on "|" rather than ":" because IPv6 addresses
    # (e.g. "::1", "2001:db8::1") legitimately contain colons; splitting a
    # colon-delimited challenge string on ":" silently mis-parses every
    # IPv6 client and makes verify() always fail for them. "|" never
    # appears in an IP literal, a decimal timestamp, or a decimal
    # difficulty, so it's a safe, unambiguous delimiter for this format.
    method create_challenge ($client_ip) {
        my $now       = int(time());
        my $expires   = $now + $ttl;
        my $payload   = "${client_ip}|${expires}|${difficulty}";
        my $signature = substr(hmac_sha256_hex($payload, $secret), 0, 16);

        return {
            challenge  => "${payload}|${signature}",
            difficulty => $difficulty,
            expires    => $expires,
        };
    }

    method verify ($challenge_str, $nonce, $client_ip) {
        return 0 unless defined $challenge_str && defined $nonce;

        my ($ip, $expires, $diff, $sig) = split(/\|/, $challenge_str, 4);
        return 0 unless defined $ip && length $ip
                      && defined $expires && length $expires
                      && defined $diff && length $diff
                      && defined $sig && length $sig;

        # 1. IP validation
        return 0 if $ip ne $client_ip;

        # 2. Expiration validation
        return 0 if time() > $expires;

        # 3. HMAC signature integrity check (constant-time comparison to
        #    avoid leaking signature bytes via response-timing side channel)
        my $expected_payload = "${ip}|${expires}|${diff}";
        my $expected_sig     = substr(hmac_sha256_hex($expected_payload, $secret), 0, 16);
        return 0 unless _secure_compare($sig, $expected_sig);

        # 4. Hash collision check (Proof-of-Work verification)
        my $hash   = sha256_hex("${challenge_str}:${nonce}");
        my $target = '0' x $diff;

        return index($hash, $target) == 0;
    }

    sub _secure_compare ($a, $b) {
        return 0 unless length($a) == length($b);
        my $diff = 0;
        $diff |= ord(substr($a, $_, 1)) ^ ord(substr($b, $_, 1)) for 0 .. length($a) - 1;
        return $diff == 0;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::BotProtection::ProofOfWork - Stateless Proof-of-Work Bot Mitigation Engine

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI::BotProtection::ProofOfWork;

    my $pow = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        difficulty => 4,
        secret     => 'app_secret_key',
        ttl        => 300,
    );

    # Generate a signed challenge for an incoming IP
    my $challenge = $pow->create_challenge('192.168.1.100');

    # Verify client submission
    my $is_valid = $pow->verify(
        $challenge->{challenge},
        $client_nonce,
        '192.168.1.100'
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::BotProtection::ProofOfWork> provides a stateless,
cryptographic Proof-of-Work (PoW) challenge-and-response engine designed to
mitigate automated web scraping, credential stuffing, and bot attacks.

When a client requests access, the engine generates an HMAC-signed challenge
requiring the client's browser to compute a SHA-256 hash collision (finding
a nonce that yields a hash beginning with a set number of leading zeros).

Because verification relies on HMAC signatures, the engine is entirely
stateless and does not require shared memory, database storage, or external
caching backends.

Challenge strings are safe to use with both IPv4 and IPv6 client addresses;
internally, fields are delimited with C<|> rather than C<:>, since IPv6
literals (e.g. C<::1>, C<2001:db8::1>) contain colons themselves.

=head1 CONSTRUCTOR

=head2 C<new(%options)>

Instantiates a new Proof-of-Work engine. Accepts the following named parameters:

=over 4

=item * C<difficulty> (Optional)

Integer specifying the number of leading hexadecimal zeros required in the
calculated SHA-256 hash collision. Higher values exponentially increase CPU
effort for the client while keeping server verification costs near instant.
Defaults to C<3>.

=item * C<secret> (Optional)

A secret seed scalar used to generate HMAC signatures for challenges.
B<Must be customized in production environments> to prevent challenge
tampering or forgery. Defaults to C<'change_me_in_production'>.

=item * C<ttl> (Optional)

Integer specifying the validity window of generated challenges in seconds.
Defaults to C<300> (5 minutes).

=back

=head1 METHODS

=head2 C<create_challenge($client_ip)>

    my $data = $pow->create_challenge('10.0.0.1');

Generates a signed challenge string bound to the client's IP address,
difficulty level, and timestamp.

Returns a HashRef containing:

=over 4

=item * C<challenge>: The signed challenge token string.

=item * C<difficulty>: The difficulty integer.

=item * C<expires>: The UNIX expiration epoch.

=back

=head2 C<verify($challenge_str, $nonce, $client_ip)>

    my $bool = $pow->verify($challenge_str, $nonce, $client_ip);

Validates a client's Proof-of-Work solution. Performs signature integrity verification, expiration checking, IP matching, and cryptographic hash collision calculation.

Returns C<1> if valid, or C<0> if verification fails.

=head1 SEE ALSO

L<PAGI::FastAPI::Middleware::BotProtection>, L<PAGI::FastAPI>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::BotProtection::ProofOfWork

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::BotProtection::ProofOfWork
