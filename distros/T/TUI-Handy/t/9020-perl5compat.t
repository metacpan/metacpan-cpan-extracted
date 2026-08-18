use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9020-perl5compat.t - static scan for tokens that do not exist in
# Perl 5.005_03 (or are barred by the ina@CPAN house style): our, say,
# state, the // defined-or operator, \x{...}, and 3-argument open.
#
# The // check uses operator signatures (a term immediately followed by //)
# so that an empty substitution replacement such as s/\r$// is not flagged.
#
# This is the distribution's own, stricter form of INA_CPAN_Check check_D,
# so t/9000-ina-cpan-check.t does not call check_D as well.

use lib 't/lib';
use INA_CPAN_Check;

sub scan_file {
    my $file = shift;
    local *FH;
    open(FH, "<$file") or return ("cannot-open");
    binmode FH;
    local $/;
    my $src = <FH>;
    close FH;
    $src = '' unless defined $src;

    $src =~ s/\r//g;                        # tolerate a CRLF checkout
    $src =~ s/^=\w.*?^=cut[^\n]*\n?//gms;   # drop POD blocks
    $src =~ s/^__(?:END|DATA)__.*\z//ms;    # drop trailing data section

    my @bad;
    my $ln = 0;
    for my $raw (split /\n/, $src) {
        $ln++;
        my $line = $raw;

        # defined-or as an operator: $var // ... , ) // ... , method-call // ...
        if ($line =~ m{(?:\$\w+|\)|\]|\})\s*//(?:[=\s]|\$|\@|\%)}
         || $line =~ m{->\w+\s*//}
         || $line =~ m{//=}) {
            push @bad, "defined-or\@$ln";
        }

        if ($line =~ /\\x\{/) {
            push @bad, "\\x{}\@$ln";
        }

        # 3-argument open: open(FH, MODE, EXPR)
        if ($line =~ /\bopen\s*\([^,)]+,\s*[^,)]*,\s*[^)]+\)/) {
            push @bad, "3arg-open\@$ln";
        }

        # Word tokens: strip quoted strings and comments first so that
        # words appearing inside literals are not misread as code.
        my $c = $raw;
        $c =~ s/\\.//g;
        $c =~ s/'[^']*'//g;
        $c =~ s/"[^"]*"//g;
        $c =~ s/#.*$//;
        push @bad, "our\@$ln"   if $c =~ /\bour\b/;
        push @bad, "state\@$ln" if $c =~ /\bstate\s*[\$\@\%]/;
        push @bad, "say\@$ln"   if $c =~ /(?:^|;|\{)\s*say\s/;
    }
    return @bad;
}

# Targets: the shippable module and the t/9xxx maintenance tests, which are
# themselves required to be 5.005_03-clean.  Functional t/000x fixtures are
# out of scope: they may carry fixture data on purpose.
#
# t/lib/INA_CPAN_Check.pm is out of scope for the same reason this file is
# out of scope for itself: it is a scanner, so it necessarily carries the
# forbidden tokens as regex data (qr/\bour\b/ and friends) and every such
# pattern would be reported as a use of the token.  It is checked instead by
# the P1-P12 pass that 'pmake dist' runs over lib/*.pm, t/9NNN*.t and
# t/lib/*.pm, whose cleaner understands a pattern literal.
my @targets = ('lib/TUI/Handy.pm');

# The scanner necessarily contains the forbidden-token patterns as data, so
# it is excluded from its own scan (matched by basename against $0).  $0 may
# arrive with either separator, so both are stripped.
my $self = $0;
$self =~ s{.*[\\/]}{};
if (opendir(D, 't')) {
    my @t = sort grep { /^9\d{3}-.*\.t$/ && $_ ne $self } readdir(D);
    closedir(D);
    for my $f (@t) {
        push @targets, "t/$f";
    }
}

my @tests;
for my $file (@targets) {
    my $f = $file;
    push @tests, sub {
        my @bad = scan_file($f);
        ok(!@bad, "$f is 5.005_03-clean" . (@bad ? " (@bad)" : ''));
    };
}

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
