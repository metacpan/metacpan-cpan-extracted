######################################################################
#
# 0010-clean-corpus-stack.t - Clean-corpus regression test (batch 2).
#
# Scans a second corpus of real, published ina@CPAN module sources that
# are known to be Perl 5.005_03 compatible, and asserts that OrDie
# reports ZERO violations for every one of them.  Like 0009, this
# guards against future BLACKLIST / masker changes introducing false
# positives against genuine clean code -- here exercised against much
# larger and, in part, multibyte (MBCS) sources.
#
# The corpus lives under t/corpus-stack/<distribution>/lib/... (a
# sibling of t/corpus/, so the 0009 walker never descends into it) and
# consists of the shipped library modules (lib/*.pm) of:
#
#   the Handy runtime stack          the character-encoding libraries
#   --------------------------       --------------------------------
#   PSGI-Handy   (5 modules)         Jacode      (dispatcher)
#   HTTP-Handy                       mb          (MBCS source)
#   DB-Handy                         Jacode4e    (MBCS source)
#   HP-Handy                         Jacode4e-RoundTrip (MBCS source)
#
# These are the files that must remain 5.005_03-clean per each
# distribution's own t/9020-perl5compat.t contract.  Distribution
# feature-test files are intentionally NOT part of the corpus: they
# carry version-guarded modern fixtures by design and lie outside the
# 5.005_03 compatibility scope.  Only lib/*.pm shipping modules are
# included.
#
# Three of the sources (mb.pm, Jacode4e.pm, Jacode4e/RoundTrip.pm) are
# not US-ASCII; they are read with binmode and fed verbatim to
# check_source, which masks string/comment/POD/heredoc/regex bodies
# before testing.  The corpus tree is exempted from the US-ASCII check
# in t/9010-encoding.t (the same exemption already granted to doc/).
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

my $CORPUS = File::Spec->catdir($ROOT, 't', 'corpus-stack');

# --------------------------------------------------------------------
# Recursively collect every *.pm file under t/corpus-stack.
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
