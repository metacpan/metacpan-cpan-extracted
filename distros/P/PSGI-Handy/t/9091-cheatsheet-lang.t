######################################################################
# 9091-cheatsheet-lang.t - verify each doc/<name>.XX.txt cheat sheet's
# header language NAME matches its [XX] language code.
#
# Why: the doc cheat-sheet check only verifies that the [XX] tag is
# present, not that the language actually written matches the code. A
# file tagged [BM] must really be Bahasa Melayu, not some other language
# whose two-letter code happens to collide (e.g. ISO 639-1 "bm" =
# Bambara). This catches code/name swaps that the [XX] check misses.
#
# Portable: drop into any distribution's t/. It discovers cheat sheets
# from the MANIFEST (doc/*.XX.txt) and uses no non-core modules, so it
# runs unchanged on Perl 5.005_03 and later. Native-script autonyms are
# written as raw UTF-8 byte escapes (\xNN) so this source file stays
# US-ASCII while still matching the native bytes inside each cheat sheet.
#
# ina closure-array pattern: one assertion per closure; the plan count is
# derived from scalar(@tests) and never hard-coded.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();

my $ROOT = "$FindBin::Bin/..";

# --- minimal TAP helpers (no Test::More: must run on 5.005_03) -------
my $count = 0;
sub ok {
    my ($cond, $label) = @_;
    $count++;
    print(($cond ? "ok" : "not ok") . " $count - " . (defined $label ? $label : '') . "\n");
    return $cond;
}

# Independent expected language-name token per code. The header text
# after [XX] must CONTAIN this token. Latin-script names are plain
# ASCII; non-Latin autonyms are UTF-8 byte sequences (\xNN).
my %expect = (
    BM => 'Bahasa Melayu',                                                          # Malay
    EN => 'English',
    ID => 'Bahasa Indonesia',
    TL => 'Filipino',
    UZ => "O'zbek",
    FR => 'Fran',                                                                   # ASCII prefix of "Francais"
    TR => "T\xc3\xbcrk\xc3\xa7e",                                                   # Turkce
    VI => "Vi\xe1\xbb\x87t",                                                        # Viet
    MN => "\xd0\x9c\xd0\xbe\xd0\xbd\xd0\xb3\xd0\xbe\xd0\xbb",                       # Mongol (Cyrillic)
    JA => "\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e",                                   # Japanese
    ZH => "\xe7\xae\x80\xe4\xbd\x93",                                               # Simplified Chinese
    TW => "\xe7\xb9\x81\xe9\xab\x94",                                               # Traditional Chinese
    KO => "\xed\x95\x9c\xea\xb5\xad\xec\x96\xb4",                                   # Korean
    TH => "\xe0\xb9\x84\xe0\xb8\x97\xe0\xb8\xa2",                                   # Thai
    HI => "\xe0\xa4\xb9\xe0\xa4\xbf\xe0\xa4\x82\xe0\xa4\xa6\xe0\xa5\x80",           # Hindi
    BN => "\xe0\xa6\xac\xe0\xa6\xbe\xe0\xa6\x82\xe0\xa6\xb2\xe0\xa6\xbe",           # Bangla
    MY => "\xe1\x80\x97\xe1\x80\x99\xe1\x80\xac",                                   # Burmese
    KM => "\xe1\x9e\x81\xe1\x9f\x92\xe1\x9e\x98\xe1\x9f\x82\xe1\x9e\x9a",           # Khmer
    NE => "\xe0\xa4\xa8\xe0\xa5\x87\xe0\xa4\xaa\xe0\xa4\xbe\xe0\xa4\xb2\xe0\xa5\x80", # Nepali
    SI => "\xe0\xb7\x83\xe0\xb7\x92\xe0\xb6\x82\xe0\xb7\x84\xe0\xb6\xbd",           # Sinhala
    UR => "\xd8\xa7\xd8\xb1\xd8\xaf\xd9\x88",                                       # Urdu
);

# --- read the cheat-sheet list from the MANIFEST --------------------
sub manifest_docs {
    my @docs;
    local *MF;
    open(MF, "< $ROOT/MANIFEST") or return ();
    while (<MF>) {
        $_ =~ s/\r?\n$//;
        $_ =~ s/\s+.*$//;            # strip optional comment after the path
        next unless /^doc\/.+\.txt$/;
        push @docs, $_;
    }
    close(MF);
    return @docs;
}

# first non-empty, non-rule (=...) line, as raw bytes
sub header_line {
    my ($path) = @_;
    my $line = '';
    local *FH;
    open(FH, "< $path") or return '';
    binmode FH;
    while (<FH>) {
        $_ =~ s/\r?\n$//;
        if (/\S/ && !/^=/) { $line = $_; last; }
    }
    close(FH);
    return $line;
}

my @docs = manifest_docs();

my @tests;
if (!@docs) {
    push @tests, sub { ok(1, 'no doc/*.txt cheat sheets in MANIFEST (skipped)'); };
}
else {
    my $doc;
    for $doc (@docs) {
        my $path = "$ROOT/$doc";
        push @tests, sub {
            my $code = '';
            $code = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;
            if (!-f $path) {
                return ok(0, "cannot find $doc");
            }
            my $hdr = header_line($path);
            my $after = '';
            $after = $1 if $hdr =~ /\[\Q$code\E\]\s*(.*)$/;
            if (!exists $expect{$code}) {
                return ok(0, "unknown language code [$code] in $doc"
                            . " (add it to %expect to confirm the language name)");
            }
            my $want = $expect{$code};
            my $hit  = (index($after, $want) >= 0) ? 1 : 0;
            ok($hit, "header language matches code [$code]: $doc"
                     . ($hit ? '' : " (text after [$code] does not contain the expected name)"));
        };
    }
}

print "1.." . scalar(@tests) . "\n";
my $t;
for $t (@tests) {
    $t->();
}
