######################################################################
#
# 0009-clean-corpus.t - Clean-corpus regression test.
#
# Scans a corpus of real, published ina@CPAN module sources that are
# known to be Perl 5.005_03 compatible, and asserts that OrDie reports
# ZERO violations for every one of them.  This guards against future
# changes to the BLACKLIST / masker introducing false positives against
# genuine clean code.
#
# The corpus lives under t/corpus/<distribution>/lib/... and consists of
# the shipped library modules (lib/*.pm) of:
#
#   CSV-LINQ      LTSV-LINQ     JSON-LINQ     mb-JSON
#   Modern-Open   Perl7-Handy   BATsh         UTF8-R2
#
# These are the files that must remain 5.005_03-clean per each
# distribution's own t/9020-perl5compat.t contract.  Distribution
# feature-test files (e.g. 3-argument open() tests, signature tests,
# \R / \x{} regex tests) are intentionally NOT part of the corpus: they
# carry version-guarded modern fixtures by design and lie outside the
# 5.005_03 compatibility scope.
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
use INA_CPAN_Check qw(ok diag);
use Perl500503Syntax::OrDie ();

# Locate the distribution root whether run from the root or from t/.
my $ROOT = do {
    -f File::Spec->catfile('lib', 'Perl500503Syntax', 'OrDie.pm')
        ? File::Spec->curdir()
        : File::Spec->updir();
};

my $CORPUS = File::Spec->catdir($ROOT, 't', 'corpus');

# --------------------------------------------------------------------
# Recursively collect every *.pm file under t/corpus.
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

my @corpus = ();
_collect($CORPUS, \@corpus);
@corpus = sort @corpus;

my @tests = ();

# Guard: the corpus must not be empty, or the file scan would vacuously
# pass.  We expect at least 8 module files (one+ per distribution).
push @tests, sub {
    ok(scalar(@corpus) >= 8,
       'corpus is present (>= 8 module files found, got ' . scalar(@corpus) . ')');
};

# One assertion per corpus file: OrDie must report zero violations.
my $file;
foreach $file (@corpus) {
    my $rel = $file;
    $rel =~ s/^\Q$CORPUS\E[\\\/]?//;
    $rel =~ s/\\/\//g;
    push @tests, sub {
        my $src = _slurp_bin($file);
        if (!defined $src) {
            ok(0, "readable: $rel");
            return;
        }
        my @v = Perl500503Syntax::OrDie::check_source($src, $rel);
        my $n = scalar(@v);
        ok($n == 0, "clean (no 5.005_03 violations): $rel");
        if ($n) {
            diag("  $_") for @v;
        }
    };
}

print '1..' . scalar(@tests) . "\n";
$_->() for @tests;
