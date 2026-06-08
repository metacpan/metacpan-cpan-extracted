######################################################################
# 9080-cheatsheets.t  doc/ cheat sheet quality checks.
#
# Checks each doc/psgi_cheatsheet.XX.txt listed in the MANIFEST:
#   S1  Native script present for languages that use a non-Latin script
#   S2  Section numbers are consecutive [1..N]
#   S3  Header line format: product name + [XX] lang-name
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my @manifest  = _manifest_files($ROOT);
my @doc_files = sort grep { m{^doc/.*\.txt$} && -f "$ROOT/$_" } @manifest;

plan_skip('no doc/*.txt files found') unless @doc_files;
plan_tests(scalar(@doc_files) * 3);

# Languages whose native script is non-Latin (so the file must contain
# at least one non-ASCII byte). Latin-script codes are not required to.
my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN MY KM MN NE SI UR);

my $doc;
for $doc (@doc_files) {
    my $path = "$ROOT/$doc";
    my $lang = '';
    $lang = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;

    # S1: native script present when required
    if ($lang && $native_script{$lang}) {
        local *FHS1;
        open FHS1, "< $path" or do {
            ok(0, "S1 - doc/ cannot open: $doc");
            ok(1, "S2 - skipped"); ok(1, "S3 - skipped"); next;
        };
        binmode FHS1;
        my $raw = do { local $/; <FHS1> }; close FHS1;
        my $non_ascii = 0;
        my $i;
        for ($i = 0; $i < length($raw); $i++) {
            if (ord(substr($raw, $i, 1)) > 127) { $non_ascii = 1; last }
        }
        ok($non_ascii,
           "S1 - doc/ native script present [$lang]: $doc");
    }
    else {
        ok(1, "S1 - doc/ native script not required [$lang]: $doc");
    }

    # S2: consecutive section numbers [ 1. ] [ 2. ] ...
    local *FHS2;
    open FHS2, "< $path" or do {
        ok(0, "S2 - cannot open: $doc"); ok(1, "S3 - skipped"); next;
    };
    my $doc_text = do { local $/; <FHS2> }; close FHS2;
    my @nums = ($doc_text =~ /^\[ (\d+)\./mg);
    my $s2 = scalar(@nums) ? 1 : 0;
    my $j;
    for ($j = 0; $j <= $#nums; $j++) {
        if ($nums[$j] != $j + 1) { $s2 = 0; last }
    }
    ok($s2,
       "S2 - doc/ section numbers consecutive [1.." . scalar(@nums) . "]: $doc"
       . ($s2 ? '' : " (got: @nums)"));

    # S3: header line must contain [XX] matching the filename lang code
    my $first_line = '';
    local *FHS3;
    open FHS3, "< $path" or do { ok(0, "S3 - cannot open: $doc"); next };
    while (<FHS3>) {
        $_ =~ s/\r?\n$//;
        if (/\S/ && !/^=/) { $first_line = $_; last }
    }
    close FHS3;
    my $s3 = ($lang && $first_line =~ /\[$lang\]/) ? 1 : 0;
    ok($s3,
       "S3 - doc/ header contains [$lang] language code: $doc"
       . ($s3 ? '' : " (header: $first_line)"));
}

END { end_testing() }
