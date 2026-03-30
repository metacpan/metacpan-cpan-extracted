use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# skip if openssl not available
my $quiet = ($^O eq 'MSWin32' ? '2>nul' : '2>/dev/null');
my $openssl = `openssl version $quiet`;
plan skip_all => 'openssl not available' unless $openssl =~ /SSL/;

# TSA test requires network — opt-in only
plan skip_all => 'TSA tests skipped (set TSA_TEST=1 to enable)'
    unless $ENV{TSA_TEST};

my $has_curl = `curl --version $quiet`;
my $has_lwp  = eval { require LWP::UserAgent; 1 };
plan skip_all => 'curl or LWP::UserAgent required for TSA test'
    unless $has_curl || $has_lwp;

use PDF::Sign qw(config ts_query tsa_fetch);

my $tmpdir = tempdir(CLEANUP => 1);
my $infile = "$tmpdir/input.pdf";


# ============================================================
# create a minimal fake PDF input
# ============================================================
open(my $fh, '>:raw', $infile) or die "Cannot write: $!";
print $fh "%PDF-1.4\nfake PDF content for TSA test\n%%EOF\n";
close $fh;

# ============================================================
# configure PDF::Sign
# ============================================================
config(
    osslcmd     => 'openssl',
    tmpdir      => $tmpdir,
);

my $tsqfile = "$infile.tsq";

# ============================================================
# test ts_query
# ============================================================
eval { ts_query(in => $infile, out => $tsqfile) };
ok(!$@,       'ts_query did not die')     or diag "Error: $@";
ok(-e $tsqfile, 'ts_query created .tsq file');

SKIP: {
    skip '.tsq file not created', 4 unless -e $tsqfile;

    # verify .tsq is a valid DER file (starts with 0x30)
    open(my $qfh, '<:raw', $tsqfile) or die $!;
    my $byte;
    read($qfh, $byte, 1);
    close $qfh;
    is(ord($byte), 0x30, '.tsq is valid DER (starts with SEQUENCE 0x30)');

    # ============================================================
    # test tsa_fetch
    # ============================================================
    my $token = eval {
        tsa_fetch(tsq => $tsqfile, tsa_url => $PDF::Sign::tsaserver)
    };
    ok(!$@,                         'tsa_fetch did not die')          or diag "Error: $@";
    ok(defined $token && length($token) > 0,
                                    'tsa_fetch returned non-empty token');

    SKIP: {
        skip 'no token to inspect', 1 unless defined $token && length $token;

        # TimeStampToken DER starts with 0x30
        my $first_byte = ord(substr($token, 0, 1));
        is($first_byte, 0x30, 'TimeStampToken is valid DER (starts with SEQUENCE 0x30)');
    }
}

diag "openssl version: " . (split /\n/, $openssl)[0];
diag "TSA server: $PDF::Sign::tsaserver";

done_testing();
