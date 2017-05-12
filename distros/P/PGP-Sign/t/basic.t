# basic.t -- Basic tests for PGP::Sign functionality.  -*- perl -*-
# $Id: basic.t 173 2007-04-27 23:51:24Z eagle $

# Locate our test data directory for later use.
my $data;
for (qw(./data ../data)) { $data = $_ if -d $_ }
unless ($data) { die "Cannot find PGP data directory\n" }
$PGP::Sign::PGPPATH = $data;

# Open and load our data file.  This is the sample data that we'll be
# signing and checking signatures against.
open (DATA, "$data/message") or die "Cannot open $data/message: $!\n";
@data = <DATA>;
close DATA;

# The key ID and pass phrase to use for testing.
my $keyid = 'testing';
my $passphrase = 'testing';

# Print out the count of tests we'll be running.
BEGIN { $| = 1; print "1..14\n" }

# 1 (ensure module can load)
END { print "not ok 1\n" unless $loaded }
use PGP::Sign;
use FileHandle;
$loaded = 1;
print "ok 1\n";

# 2 (generate signature)
my ($signature, $version) = pgp_sign ($keyid, $passphrase, @data);
my @errors = PGP::Sign::pgp_error;
print 'not ' if @errors;
print "ok 2\n";
warn @errors if @errors;

# 3 (check signature)
my $signer = pgp_verify ($signature, $version, @data);
@errors = PGP::Sign::pgp_error;
print 'not ' if ($signer ne 'testing' || @errors);
print "ok 3\n";
warn @errors if @errors;

# 4 (check signature w/o version, which shouldn't matter)
$signer = pgp_verify ($signature, undef, @data);
@errors = PGP::Sign::pgp_error;
print 'not ' if ($signer ne 'testing' || @errors);
print "ok 4\n";
warn @errors if @errors;

# 5 (check failed signature)
$signer = pgp_verify ($signature, $version, @data, "xyzzy");
print 'not ' if ($signer ne '' || PGP::Sign::pgp_error);
print "ok 5\n";

# 6 (whitespace munging)
$PGP::Sign::MUNGE = 1;
my @munged = @data;
for (@munged) { s/\n/ \n/ }
($signature, $version) = pgp_sign ($keyid, $passphrase, @munged);
$PGP::Sign::MUNGE = 0;
print 'not ' if PGP::Sign::pgp_error;
print "ok 6\n";

# 7 (check a signature of munged data against the munged version)
$signer = pgp_verify ($signature, $version, @data);
print 'not ' if ($signer ne 'testing' || PGP::Sign::pgp_error);
print "ok 7\n";

# 8 (check signature of munged data against unmunged data with MUNGE)
$PGP::Sign::MUNGE = 1;
$signer = pgp_verify ($signature, $version, @munged);
$PGP::Sign::MUNGE = 0;
print 'not ' if ($signer ne 'testing' || PGP::Sign::pgp_error);
print "ok 8\n";

# 9 (check signature of munged data against unmunged data w/o MUNGE)
# Whether this signature verifies under GnuPG depends on the version of
# GnuPG; GnuPG 1.0.2 and higher verify it, but GnuPG 1.0.1 doesn't.
# Earlier versions do verify it.  This is a disagreement over how to
# handle trailing whitespace when verifying signatures.
if ($PGP::Sign::PGPSTYLE eq 'GPG') {
    print "ok 9 # skip -- unreliable on GnuPG\n";
} else {
    $signer = pgp_verify ($signature, $version, @munged);
    print 'not ' if ($signer ne '' || PGP::Sign::pgp_error);
    print "ok 9\n";
}

# 10 (take data from a code ref)
my $munger = sub {
    local $_ = shift @munged;
    s/ +$// if defined;
    $_
};
$signature = pgp_sign ($keyid, $passphrase, $munger);
print 'not ' if PGP::Sign::pgp_error;
print "ok 10\n";

# 11 (check the resulting signature)
$signer = pgp_verify ($signature, undef, @data);
@errors = PGP::Sign::pgp_error;
print 'not ' if ($signer ne 'testing' || @errors);
print "ok 11\n";
warn @errors if @errors;

# 12 (check an external PGP 2.6.2 signature, data from glob ref)
if ($PGP::Sign::PGPSTYLE eq 'GPG') {
    print "ok 12 # skip -- GnuPG doesn't have IDEA\n";
} else {
    if (open (SIG, "$data/message.sig") && open (DATA, "$data/message")) {
        my @signature = <SIG>;
        close SIG;
        $signature = join ('', @signature[3..6]);
        $signer = pgp_verify ($signature, undef, \*DATA);
        close DATA;
        @errors = PGP::Sign::pgp_error;
        if ($signer ne 'R. Russell Allbery <rra@stanford.edu>'
            || PGP::Sign::pgp_error) {
            print "# Saw '$signer'\n";
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 12\n";
}

# 13 (check an external version three DSA signature, data from array ref)
if ($PGP::Sign::PGPSTYLE eq 'PGP2') {
    print "ok 13 # skip -- PGP 2 can't verify DSA signatures\n";
} else {
    if (open (SIG, "$data/message.asc")) {
        my @signature = <SIG>;
        close SIG;
        $signature = join ('', @signature[4..6]);
        $signer = pgp_verify ($signature, undef, \@data);
        @errors = PGP::Sign::pgp_error;
        if ($signer ne 'Russ Allbery <rra@stanford.edu>'
            || PGP::Sign::pgp_error) {
            print "# Saw '$signer'\n";
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 13\n";
}

# 14 (check an external version four DSA signature, data from FileHandle)
if ($PGP::Sign::PGPSTYLE ne 'GPG') {
    print "ok 14 # skip -- only GnuPG can verify version 4 signatures\n";
} else {
    if (open (SIG, "$data/message.asc.v4")) {
        my @signature = <SIG>;
        close SIG;
        my $fh = new FileHandle ("$data/message");
        my $signer;
        if ($fh) {
            $signature = join ('', @signature[4..6]);
            $signer = pgp_verify ($signature, undef, $fh);
            @errors = PGP::Sign::pgp_error;
        }
        if ($signer ne 'Russ Allbery <rra@stanford.edu>'
            || PGP::Sign::pgp_error) {
            print "# Saw '$signer'\n";
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 14\n";
}
