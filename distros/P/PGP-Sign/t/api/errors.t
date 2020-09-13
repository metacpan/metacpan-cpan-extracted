#!/usr/bin/perl
#
# Tests for error handling.
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

use IPC::Cmd qw(can_run);
use Test::More;
use Test::PGP qw(gpg_is_new_enough);

# Check that GnuPG is available.  If so, load the module and set the plan.
BEGIN {
    if (!can_run('gpg')) {
        plan skip_all => 'gpg binary not available';
    } elsif (!gpg_is_new_enough('gpg')) {
        plan skip_all => 'gpg binary is older than 1.4.20 or 2.1.23';
    } else {
        plan tests => 4;
        use_ok('PGP::Sign');
    }
}

# Locate our test data directory for later use.
my $data = 't/data';

# Open and load our data file.  This is the sample data that we'll be signing
# and checking signatures against.
open(my $fh, '<', "$data/message");
my @data = <$fh>;
close($fh);

# The key ID and pass phrase to use for testing.
my $keyid      = 'testing';
my $passphrase = 'testing';

# First, a bad style argument to the constructor.
undef $@;
my $signer = eval { PGP::Sign->new({ style => 'foo' }) };
like(
    $@,
    qr{^Unknown [ ] OpenPGP [ ] backend [ ] style [ ] foo}xms,
    'Bad style argument',
);

# A path to a nonexistent binary.
$signer = PGP::Sign->new({ path => '/nonexistent/binary' });
undef $@;
my $signature = eval { $signer->sign($keyid, $passphrase, @data) };
ok($@, 'Bad path to GnuPG binary');

# Verification of a completely invalid signature.
$signer = PGP::Sign->new();
undef $@;
eval { $signer->verify('adfasdfasdf', @data) };
like($@, qr{Execution [ ] of [ ] gpg [ ] failed}xms, 'Invalid signature');
