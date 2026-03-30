use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# skip entire test if openssl not available
my $quiet = ($^O eq 'MSWin32' ? '2>nul' : '2>/dev/null');
my $openssl = `openssl version $quiet`;
plan skip_all => 'openssl not available' unless $openssl =~ /SSL/;
use PDF::Sign qw(config :sign :ts);

my $tmpdir = tempdir(CLEANUP => 1);
my $cert   = "$tmpdir/cert.pem";
my $key    = "$tmpdir/key.pem";
my $infile = "$tmpdir/input.pdf";

# ============================================================
# generate self-signed certificate for testing
# ============================================================
my $gen = system(
    'openssl', 'req', '-x509', '-newkey', 'rsa:2048',
    '-keyout', $key,
    '-out',    $cert,
    '-days',   '1',
    '-nodes',
    '-subj',   '/C=IT/O=PDF-Sign-Test/CN=PDF-Sign Test Certificate',
    '-config', 'openssl.cnf'
);
plan skip_all => 'openssl could not generate test certificate' if $gen != 0;
ok(-e $cert, 'self-signed certificate generated');
ok(-e $key,  'private key generated');

# ============================================================
# create a real PDF input
# ============================================================
# PDF backend: PDF::API2 or PDF::Builder
my $PDF_BACKEND;
if (eval { require PDF::API2; PDF::API2->import(); 1 }) {
    $PDF_BACKEND = 'PDF::API2';
} elsif (eval { require PDF::Builder; PDF::Builder->import(); 1 }) {
    $PDF_BACKEND = 'PDF::Builder';
} else {
    die "PDF::Sign requires PDF::API2 or PDF::Builder\n";
}

my $pdfin;
{
	no strict 'refs';
	$pdfin = $PDF_BACKEND->new();
}
my $page = $pdfin->page();
$page->size('A4'); 
my $content = $page->text();
$content->fill_color("#000");
my $font = $pdfin->font('Helvetica');
$content->textlabel(297.5,500,$font,14,"Test Page",align=>"center");
$pdfin->saveas($infile);
ok(-e $infile,  'test pdf generated');

# ============================================================
# configure PDF::Sign
# ============================================================
config(
    osslcmd     => 'openssl',
    x509_pem    => $cert,
    privkey_pem => $key,
    tmpdir      => $tmpdir,
);

# ============================================================
# test sign_file
# ============================================================
my $pdfout; 
{
    no strict 'refs';
    $pdfout = $PDF_BACKEND->open($infile);
}
diag "$pdfout";
eval {
    prepare_file($pdfout,0);
};
ok(!$@,                        'prepare_file did not die')           or diag "Error: $@";
my $signed = eval {
    sign_file($pdfout)
};
ok(!$@,                        'sign_file did not die')           or diag "Error: $@";
ok(defined $signed,         'sign_file returned a value');
ok($signed =~ m/<3082/sm ,     'sign_file returned non-empty signature');

SKIP: {
    skip 'no signature to inspect', 2 unless defined $signed && length $signed;
}

done_testing();
