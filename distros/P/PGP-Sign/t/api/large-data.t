#!/usr/bin/perl
#
# Test for handling of large data in PGP::Sign.
#
# Copyright 2020 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.020;
use autodie;
use warnings;

use lib 't/lib';

use File::Spec;
use IPC::Cmd qw(can_run);
use Test::More;
use Test::PGP qw(gpg_is_gpg1 gpg_is_new_enough);

# Check that GnuPG is available.  If so, load the module and set the plan.
BEGIN {
    if (!can_run('gpg')) {
        plan skip_all => 'gpg binary not available';
    } elsif (!gpg_is_new_enough('gpg')) {
        plan skip_all => 'gpg binary is older than 1.4.20 or 2.1.23';
    } else {
        plan tests => 3;
        use_ok('PGP::Sign');
    }
}

# The key ID and pass phrase to use for testing.
my $keyid      = 'testing';
my $passphrase = 'testing';

# Create the object to use for testing.
my $signer;
if (gpg_is_gpg1()) {
    my $home = File::Spec->catdir('t', 'data', 'gnupg1');
    $signer = PGP::Sign->new(
        {
            home  => $home,
            path  => 'gpg',
            style => 'GPG1',
        },
    );
} else {
    my $home = File::Spec->catdir('t', 'data', 'gnupg2');
    $signer = PGP::Sign->new({ home => $home });
}

# Create a long message to sign.  This is about 1MB.
my $message = ('a' x 76 . "\n") x 13618;

# Generate a signature and check that it verifies.
my $signature = $signer->sign($keyid, $passphrase, \$message);
ok($signature, 'Signature is not undef');
is($keyid, $signer->verify($signature, \$message), 'Signature verifies');
