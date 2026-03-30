use strict;
use PDF::API2;
use PDF::Sign qw(config :sign :ts);

my $pdf = PDF::API2->new();
my $page = $pdf->page();
$page->size('A4'); 
my $content = $page->text();
$content->fill_color("#000");
my $font = $pdf->font('Helvetica');
$content->textlabel(297.5,500,$font,14,"Test Page",align=>"center");

my $cert   = "cert.pem";
my $key    = "key.pem";
my $infile = "input.pdf";

$pdf->saveas($infile);
$pdf = PDF::API2->open($infile);

my $gen = system(
    'openssl', 'req', '-x509', '-newkey', 'rsa:2048',
    '-keyout', $key,
    '-out',    $cert,
    '-days',   '1',
    '-nodes',
    '-subj',   '/C=IT/O=PDF-Sign-Test/CN=PDF-Sign Test Certificate',
    '-config', 'openssl.cnf',
);

config(
    osslcmd     => 'openssl',
    x509_pem    => $cert,
    privkey_pem => $key,
    tmpdir      => '.',
);

my $signature = eval {
    cms_sign(
        signer => $cert,
        inkey  => $key,
        in     => $infile,
    )
};

prepare_file($pdf, 1);              # 0 = invisible, 1 = visible widget
my $signed = sign_file($pdf);

# timestamp
my $pdf2 = PDF::API2->from_string($signed);
prepare_ts($pdf2);
my $timestamped = ts_file($pdf2);

open(my $fh, '>:raw', 'output.pdf') or die $!;
print $fh $timestamped;
close $fh;
use Data::Dumper;
print Dumper(PDF::Sign::verify_signatures('output.pdf'));


__END__