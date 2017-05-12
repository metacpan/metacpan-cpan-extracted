# locale.t -- Test for PGP::Sign in the presence of locale.  -*- perl -*-
# $Id: locale.t 173 2007-04-27 23:51:24Z eagle $

# Set the locale.  I use French for testing; this won't be a proper test
# unless the locale is available on the local system, so hopefully this will
# be a common one.
$ENV{LC_ALL} = 'fr_FR';

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
BEGIN { $| = 1; print "1..7\n" }

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

# 4 (check failed signature)
$signer = pgp_verify ($signature, $version, @data, "xyzzy");
print 'not ' if ($signer ne '' || PGP::Sign::pgp_error);
print "ok 4\n";

# 5 (check an external PGP 2.6.2 signature, data from glob ref)
if ($PGP::Sign::PGPSTYLE eq 'GPG') {
    print "ok 5 # skip -- GnuPG doesn't have IDEA\n";
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
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 5\n";
}

# 6 (check an external version three DSA signature, data from array ref)
if ($PGP::Sign::PGPSTYLE eq 'PGP2') {
    print "ok 6 # skip -- PGP 2 can't check DSA signatures\n";
} else {
    if (open (SIG, "$data/message.asc")) {
        my @signature = <SIG>;
        close SIG;
        $signature = join ('', @signature[4..6]);
        $signer = pgp_verify ($signature, undef, \@data);
        @errors = PGP::Sign::pgp_error;
        if ($signer ne 'Russ Allbery <rra@stanford.edu>'
            || PGP::Sign::pgp_error) {
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 6\n";
}

# 7 (check an external version four DSA signature, data from FileHandle)
if ($PGP::Sign::PGPSTYLE ne 'GPG') {
    print "ok 7 # skip -- only GnuPG can verify version 4 signatures\n";
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
            print 'not ';
        }
    } else {
        print 'not ';
    }
    print "ok 7\n";
}
