######################################################################
#
# 0011-corpus-excerpt.t - Guards on the corpus fixtures under t/.
#
# Three of the corpus modules -- Jacode4e, Jacode4e::RoundTrip and mb --
# used to ship as complete copies of their distributions, 3.4 MB of the
# 5.2 MB this distribution weighed.  Almost none of it reached the
# scanner: 99% of Jacode4e.pm and 73% of mb.pm was POD, data tables and
# text after __END__, all of which the masker blanks before any stage
# runs.  They now ship as excerpts, carrying the lines the scanner
# actually reads.
#
# The reduction was verified against the full sources at the time it was
# made: the masked live code, the list of regex bodies and the list of
# string bodies were byte-identical before and after.  That comparison
# cannot be repeated here, because the full sources are deliberately not
# shipped.  What this file does instead is guard the properties that CAN
# be checked from inside the distribution:
#
#   CE01  no corpus module is large enough to be a full copy again
#   CE02  an excerpt says so, in a header, at the top
#   CE03  an excerpt names the module and version it was taken from
#   CE04  the module named in the header is the one the file declares
#   CE05  the three heavy modules are present, and are excerpts
#
# CE01 is the one that matters in practice.  A corpus is refreshed by
# copying a newer release over the old file, and the obvious way to do
# that is to copy the whole thing; the size cap turns that into a test
# failure rather than a silent return to a 5 MB distribution.
#
# Note: violations are collected into an array first and counted in
# scalar context.  A match in list context can collapse to an empty
# list and silently shift an ok() argument list, so that idiom is
# avoided here.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use File::Spec ();

use lib 'lib', File::Spec->catdir('t', 'lib');
use INA_CPAN_Check qw(ok plan_tests diag);

# Locate the distribution root whether run from the root or from t/.
my $ROOT = do {
    -f File::Spec->catfile('lib', 'Perl500503Syntax', 'OrDie.pm')
        ? File::Spec->curdir()
        : File::Spec->updir();
};

# The cap is generous: the largest excerpt is about 200 KB and the
# largest ordinary corpus module about 90 KB, while the smallest of the
# three full sources was 493 KB.  Anything above the cap is a full copy
# that came back, not a fixture that grew.
my $MAX_BYTES = 256 * 1024;

# Modules that must be present as excerpts.  These are the ones whose
# full sources are large enough to dominate the distribution.
my @MUST_BE_EXCERPT = (
    File::Spec->catfile('Jacode4e', 'lib', 'Jacode4e.pm'),
    File::Spec->catfile('Jacode4e-RoundTrip', 'lib', 'Jacode4e', 'RoundTrip.pm'),
    File::Spec->catfile('mb', 'lib', 'mb.pm'),
);

my $MARKER = 'EXCERPT -- corpus fixture';

# --------------------------------------------------------------------
# Recursively collect every *.pm file under a directory.
# A hand-rolled walk (local *DH for re-entrancy) keeps this 5.005_03
# safe and avoids any File::Find behavioural differences across Perls.
# --------------------------------------------------------------------
sub _collect {
    my ($dir, $out) = @_;
    local *DH;
    opendir(DH, $dir) or return;
    my @names = sort readdir(DH);
    closedir(DH);
    my $name;
    foreach $name (@names) {
        next if $name eq '.' || $name eq '..';
        my $path = File::Spec->catfile($dir, $name);
        if (-d $path) {
            _collect($path, $out);
        }
        elsif ($name =~ /\.pm$/) {
            push @$out, $path;
        }
    }
    return;
}

sub _slurp_bin {
    my ($path) = @_;
    local *FH;
    open(FH, $path) or return undef;
    binmode(FH);
    local $/;
    my $data = <FH>;
    close(FH);
    return $data;
}

# Only the header block is needed, and reading 200 KB of module to get
# at its first 30 lines is wasteful, so the header is taken from the
# front of the file.
sub _header {
    my ($text) = @_;
    return '' unless defined $text;
    my @l = split(/\n/, $text);
    splice(@l, 30) if @l > 30;
    return join("\n", @l);
}

my @corpus = ();
for my $sub ('corpus', 'corpus-stack') {
    my $dir = File::Spec->catdir($ROOT, 't', $sub);
    _collect($dir, \@corpus) if -d $dir;
}
@corpus = sort @corpus;

my @tests = ();

# Guard: an empty corpus would make every file-driven assertion below
# vacuous, so the count is asserted first.
push @tests, sub {
    ok(scalar(@corpus) >= 8,
       'corpus is present (>= 8 module files found, got ' . scalar(@corpus) . ')');
};

# CE01 -- size cap, over every corpus module.
my $file;
foreach $file (@corpus) {
    my $rel = $file;
    $rel =~ s/\\/\//g;
    my $f = $file;
    push @tests, sub {
        my $size = -s $f;
        $size = 0 unless defined $size;
        ok($size <= $MAX_BYTES,
           "CE01: within the $MAX_BYTES byte corpus cap ($size): $rel");
    };
}

# CE02..CE04 -- the header of every file that declares itself an excerpt.
foreach $file (@corpus) {
    my $rel = $file;
    $rel =~ s/\\/\//g;
    my $f = $file;
    my $text = _slurp_bin($file);
    $text = '' unless defined $text;
    next unless index($text, $MARKER) >= 0;

    my $head = _header($text);
    my ($declared) = $text =~ /^package\s+([\w:]+)/m;
    $declared = '' unless defined $declared;

    push @tests, sub {
        ok(index($head, $MARKER) >= 0,
           "CE02: excerpt marker is in the header: $rel");
    };
    push @tests, sub {
        my $named = ($head =~ /^#\s*Source:\s*([\w:]+)\s+(\S+)\s*$/m) ? 1 : 0;
        ok($named, "CE03: header names source module and version: $rel");
    };
    push @tests, sub {
        my $src_mod = ($head =~ /^#\s*Source:\s*([\w:]+)\s/m) ? $1 : '';
        ok($src_mod ne '' && $src_mod eq $declared,
           "CE04: header names the package the file declares"
           . " ('$src_mod' vs '$declared'): $rel");
    };
}

# CE05 -- the heavy three must be present, and must be excerpts.
my $must;
foreach $must (@MUST_BE_EXCERPT) {
    my $path = File::Spec->catfile($ROOT, 't', 'corpus-stack', $must);
    my $rel  = $must;
    $rel =~ s/\\/\//g;
    push @tests, sub {
        my $text = -f $path ? _slurp_bin($path) : undef;
        my $is_excerpt = (defined($text) && index($text, $MARKER) >= 0) ? 1 : 0;
        ok($is_excerpt, "CE05: shipped as an excerpt: $rel");
        diag("  missing: $path") unless defined $text;
    };
}

# --------------------------------------------------------------------
# Run
# --------------------------------------------------------------------
plan_tests(scalar(@tests));
$_->() for @tests;
