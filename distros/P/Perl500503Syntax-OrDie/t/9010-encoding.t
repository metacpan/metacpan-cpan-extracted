######################################################################
#
# 9010-encoding.t  Encoding hygiene for all distribution files
#
# C1: file content is US-ASCII only (no bytes > 0x7F)
# C2: no trailing whitespace
# C3: file ends with a newline
#
# Note: lib/Perl500503Syntax/OrDie.pm is excluded from the US-ASCII check
#       (POD may contain non-ASCII in future); all .t and meta files
#       must be strictly US-ASCII.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_skip('MANIFEST not found') unless -f "$ROOT/MANIFEST";

my @all  = _manifest_files($ROOT);

# Files subject to all three checks (C1 US-ASCII, C2 trailing ws, C3 newline)
# doc/ cheatsheet files are excluded from @check (non-ASCII expected);
# they are handled separately in @doc_txt below.
my @check = grep {
    /\.(?:pm|pl|t|PL|bat|txt|md|yml|json)$/i && !/^doc\//
} @all;

# doc/ cheatsheet files: skip C1 (non-ASCII expected), check C2+C3 only
my @doc_txt;
{
    my $docdir = "$ROOT/doc";
    local *_DOC_DIR;
    if (opendir(_DOC_DIR, $docdir)) {
        my @names = readdir(_DOC_DIR);
        closedir _DOC_DIR;
        for my $name (@names) {
            next unless $name =~ /\.txt$/;
            push @doc_txt, "doc/$name";
        }
    }
}
@doc_txt = sort @doc_txt;

plan_tests(scalar(@check) * 3 + scalar(@doc_txt) * 2);

for my $rel (@check) {
    my $path = "$ROOT/$rel";
    my $src  = -f $path ? _slurp($path) : '';

    ok($src !~ /[^\x00-\x7F]/, "C1: US-ASCII only: $rel");
    ok($src !~ /[ \t]+\n/,     "C2: no trailing whitespace: $rel");
    ok($src eq '' || $src =~ /\n\z/, "C3: ends with newline: $rel");
}

# doc/ files: C2 trailing whitespace + C3 ends with newline only
# (C1 US-ASCII is intentionally skipped: cheatsheets contain non-ASCII)
for my $rel (@doc_txt) {
    my $path = "$ROOT/$rel";
    my $src  = -f $path ? _slurp($path) : '';
    ok($src !~ /[ \t]+\n/,          "C2: no trailing whitespace: $rel");
    ok($src eq '' || $src =~ /\n\z/, "C3: ends with newline: $rel");
}

