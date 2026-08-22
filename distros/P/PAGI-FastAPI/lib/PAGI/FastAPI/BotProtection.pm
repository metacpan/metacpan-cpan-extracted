package PAGI::FastAPI::BotProtection;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

class PAGI::FastAPI::BotProtection {
    method create_challenge ($client_ip) {
        die "create_challenge() must be implemented by subclass";
    }

    method verify ($challenge_str, $nonce, $client_ip) {
        die "verify() must be implemented by subclass";
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::BotProtection - Base Interface for PAGI::FastAPI Bot Protection

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI;

    my $app = PAGI::FastAPI->new();

    # Enables default Proof-of-Work bot mitigation
    $app->add_bot_protection(
        difficulty => 3,
        secret     => $ENV{BOT_PROTECTION_SECRET},
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::BotProtection> serves as the base interface for bot
mitigation mechanisms in L<PAGI::FastAPI>.

By default, the framework utilises L<PAGI::FastAPI::BotProtection::ProofOfWork>
to issue stateless cryptographic challenges to unverified clients, shielding
API routes from scrapers, credential stuffers, and automated flood bots.

=head1 SUBCLASSES

=over 4

=item * L<PAGI::FastAPI::BotProtection::ProofOfWork>

Default stateless SHA-256 HMAC Proof-of-Work challenge engine.

=back

=head1 SEE ALSO

L<PAGI::FastAPI::Middleware::BotProtection>, L<PAGI::FastAPI::BotProtection::ProofOfWork>, L<PAGI::FastAPI>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::BotProtection

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

1; # End of PAGI::FastAPI::BotProtection
