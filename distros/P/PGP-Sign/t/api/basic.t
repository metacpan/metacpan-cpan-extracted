#!/usr/bin/perl
#
# Basic tests for the PGP::Sign object-oriented interface.
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
use IO::File;
use IPC::Cmd qw(can_run);
use Test::More;
use Test::PGP qw(gpg_is_gpg1 gpg2_is_new_enough);

# Check that GnuPG is available.  If so, load the module and set the plan.
BEGIN {
    if (!can_run('gpg')) {
        plan skip_all => 'gpg binary not available';
    } elsif (gpg_is_gpg1()) {
        plan skip_all => 'gpg binary is GnuPG v1';
    } elsif (!gpg2_is_new_enough('gpg')) {
        plan skip_all => 'gpg binary is older than 2.1.12';
    } else {
        plan tests => 7;
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

# Build the signer object with default parameters.
my $signer = PGP::Sign->new({ home => File::Spec->catdir($data, 'gnupg2') });

# Check a valid signature.
my $signature = $signer->sign($keyid, $passphrase, @data);
ok($signature, 'Signature is not undef');
is($keyid, $signer->verify($signature, @data), 'Signature verifies');

# Check a failed signature by adding some nonsense.  Use this to exercise
# passing a hash ref as a data source (whose string version will be used).
my %nonsense = (foo => 'bar');
is(
    q{},
    $signer->verify($signature, @data, \%nonsense),
    'Signature does not verify with added hashref',
);

# Test taking code from a code ref and then verifiying the signature.
my @code_input = @data;
my $data_ref   = sub { return shift(@code_input) };
$signature = $signer->sign($keyid, $passphrase, $data_ref);
is($keyid, $signer->verify($signature, @data), 'Signature from code ref');

# Check a modern RSA signature using a scalar reference as the data source.
open($fh, '<', "$data/message.rsa-v4.asc");
my @raw_signature = <$fh>;
close($fh);
$signature = join(q{}, @raw_signature[2 .. 11]);
my $scalar_data = join(q{}, @data);
is(
    'testing',
    $signer->verify($signature, \$scalar_data),
    'RSAv4 sig from scalar ref',
);

# Check a version 3 RSA signature using a glob as the data source.
open($fh, '<', "$data/message.rsa-v3.asc");
@raw_signature = <$fh>;
close($fh);
$signature = join(q{}, @raw_signature[2 .. 11]);
open(*DATA, '<', "$data/message");
is('testing', $signer->verify($signature, *DATA), 'RSAv3 sig from a glob');
close(*DATA);
