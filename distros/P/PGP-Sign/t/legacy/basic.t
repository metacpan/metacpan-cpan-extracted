#!/usr/bin/perl
#
# Basic tests for PGP::Sign functionality.
#
# Copyright 1998-2001, 2004, 2007, 2018, 2020 Russ Allbery <rra@cpan.org>
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
use Test::PGP qw(gpg_is_gpg1);

# Check that GnuPG is available.  If so, load the module and set the plan.
BEGIN {
    if (!can_run('gpg')) {
        plan skip_all => 'gpg binary not available';
    } else {
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

# There are three possibilities: gpg is GnuPG v1, gpg is GnuPG v2 and v1 is
# not available, or gpg is GnuPG v2 and gpg1 is GnuPG v1.  We ideally want to
# test both styles, but we'll take what we can get.
my @styles;
if (gpg_is_gpg1()) {
    @styles = qw(GPG1);
} elsif (!can_run('gpg1')) {
    @styles = qw(GPG);
} else {
    @styles = qw(GPG GPG1);
}

# Run all the tests twice, once with GnuPG v2 and then with GnuPG v1.
for my $style (@styles) {
    note("Testing PGPSTYLE $style");
    local $PGP::Sign::PGPSTYLE = $style;
    my $pgpdir = ($style eq 'GPG') ? 'gnupg2' : 'gnupg1';
    local $PGP::Sign::PGPPATH = File::Spec->catdir($data, $pgpdir);
    if ($style eq 'GPG1' && gpg_is_gpg1()) {
        $PGP::Sign::PGPS = 'gpg';
        $PGP::Sign::PGPV = 'gpg';
    }

    # Generate a signature.
    my ($signature, $version) = pgp_sign($keyid, $passphrase, @data);
    ok($signature, 'Sign');
    is(PGP::Sign::pgp_error(), q{}, '...with no errors');
    isnt($signature, undef, 'Signature');
    is(PGP::Sign::pgp_error(), q{}, '...with no errors');

    # Check signature.
    is(pgp_verify($signature, $version, @data), $keyid, 'Verify');
    is(PGP::Sign::pgp_error(),                  q{},    '...with no errors');

    # The same without version, which shouldn't matter.
    is(pgp_verify($signature, undef, @data), $keyid, 'Verify without version');
    is(PGP::Sign::pgp_error(),               q{},    '...with no errors');

    # Check a failed signature by appending some nonsense to the data.
    is(pgp_verify($signature, $version, @data, 'xyzzy'), q{},
        'Verify invalid');
    is(PGP::Sign::pgp_error(), q{}, '...with no errors');

    # Test taking code from a code ref and then verifying the reulting
    # signature.  Also test accepting only one return value from pgp_sign().
    my @code_input = @data;
    my $data_ref   = sub {
        my $line = shift(@code_input);
        return $line;
    };
    $signature = pgp_sign($keyid, $passphrase, $data_ref);
    isnt($signature, undef, 'Signature from code ref');
    is(PGP::Sign::pgp_error(),                  q{},    '...with no errors');
    is(pgp_verify($signature, $version, @data), $keyid, 'Verifies');
    is(PGP::Sign::pgp_error(),                  q{},    '...with no errors');

    # Test whitespace munging.
    {
        local $PGP::Sign::MUNGE = 1;
        ($signature, $version) = pgp_sign($keyid, $passphrase, q{       });
    }
    is(pgp_verify($signature, $version, q{       }),
        q{}, 'Munged does not match');
    is(pgp_verify($signature, $version, q{}),
        $keyid, '...but does match empty');
    {
        local $PGP::Sign::MUNGE = 1;
        is(pgp_verify($signature, $version, q{  }),
            $keyid, '...and does match munged');
    }

    # Test error handling.
    is(pgp_verify('asfasdfasf', undef, @data), undef, 'Invalid signature');
    my @errors = PGP::Sign::pgp_error();
    my $errors = PGP::Sign::pgp_error();
    like(
        $errors[-1],
        qr{^ Execution [ ] of [ ] gpg.? [ ] failed}xms,
        'Invalid signature',
    );
    like(
        $errors,
        qr{\n Execution [ ] of [ ] gpg.? [ ] failed}xms,
        'Errors contain newlines',
    );
    is($errors, join(q{}, @errors), 'Two presentations of errors match');
}

# Report the end of testing.
done_testing(21 * scalar(@styles) + 1);
