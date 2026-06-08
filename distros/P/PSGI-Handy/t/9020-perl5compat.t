######################################################################
# 9020-perl5compat.t  Perl 5.005_03 compatibility checks.
#
# Combines and extends:
#   t/0004-perl5compat.t  (P1-P13, source-level checks)
#   t/0005-cpan_precheck.t category D (D1-D6, same checks via cpan_precheck)
#
# All checks run on .pm, .t, and eg/*.pl files.
#
# Checks:
#   P1  No `our` keyword
#   P2  No say/given/state/when keywords
#   P3  No my(undef,...) list-undef
#   P4  No defined-or // operator
#   P5  No //= operator
#   P6  No ... (yada-yada) operator
#   P7  No \o{} octal escape
#   P8  No \x{NNN} wide hex escape
#   P9  No @- / @+ / $-[N] / $+[N] special variables
#   P10 $VERSION self-assignment present          (.pm only)
#   P11 warnings stub present and correct         (.pm only)
#   P12 CVE-2016-1238 pop @INC mitigation         (.pm only)
#   P13 use 5.00503; present                      (.pm only)
#   P14 Header pragma order correct               (.pm only)
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

######################################################################
# Collect files
######################################################################
my @manifest = _manifest_files($ROOT);
my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$ROOT/$_" } @manifest;
my @t_files  = sort grep { /\.t$/  && -f "$ROOT/$_" } @manifest;
my @eg_files = sort grep { m{^eg/.*\.pl$} && -f "$ROOT/$_" } @manifest;
my @all_files = (@pm_files, @t_files, @eg_files);

plan_skip('no files found') unless @all_files;

# Counts: P1-P9 for all files, P10-P14 for .pm only
my $total = scalar(@all_files) * 9
          + scalar(@pm_files)  * 5;
plan_tests($total);

######################################################################
# Helpers
######################################################################
sub _code {
    my ($path) = @_;
    my $text = _slurp("$ROOT/$path");
    $text =~ s/\n__END__\b.*\z//s;
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    return $text;
}

######################################################################
# P1-P9: All files
######################################################################
for my $f (@all_files) {
    my $code = _code($f);

    # P1: no `our`
    my @p1 = _scan_code("$ROOT/$f", qr/\bour\b/);
    ok(!@p1, "P1 - no 'our' keyword: $f");
    diag("  line $_->{line}: $_->{text}") for @p1;

    # P2: no say/given/state/when
    my @p2 = _scan_code("$ROOT/$f", qr/\b(?:say|given|state|when)\s*[\(\{]/);
    ok(!@p2, "P2 - no say/given/state/when: $f");
    diag("  line $_->{line}: $_->{text}") for @p2;

    # P3: no my(undef,...)
    my @p3 = _scan_code("$ROOT/$f", qr/\bmy\s*\(\s*undef/);
    ok(!@p3, "P3 - no my(undef,...): $f");
    diag("  line $_->{line}: $_->{text}") for @p3;

    # P4: no defined-or // (split// exempt)
    my @p4;
    {
        my $lineno = 0;
        for my $raw (split /\n/, $code) {
            $lineno++;
            next if $raw =~ /^\s*#/;
            my $cl = $raw;
            $cl =~ s/'(?:[^'\\]|\\.)*'/'_S_'/g;
            $cl =~ s/"(?:[^"\\]|\\.)*"/"_S_"/g;
            $cl =~ s{\bs/[^/]*/[^/]*/[gimsex]*}{}g;
            $cl =~ s{\bqr/[^/]*/[gimsex]*}{}g;
            $cl =~ s{\bsplit\s*/[^/]*/[gimsex]*}{}g;
            $cl =~ s{(?<![/])/(?!/)([^/\n]+)/[gimsex]*}{}g;
            $cl =~ s/#.*$//;
            if ($cl =~ /(?:[\w\$\)\}\]])  \s* \/\/ /x) {
                push @p4, { line => $lineno, text => $raw };
            }
        }
    }
    ok(!@p4, "P4 - no defined-or // operator: $f");
    diag("  line $_->{line}: $_->{text}") for @p4;

    # P5: no //=
    my @p5 = _scan_code("$ROOT/$f", qr/\/\/=/);
    ok(!@p5, "P5 - no //= operator: $f");
    diag("  line $_->{line}: $_->{text}") for @p5;

    # P6: no yada-yada
    my @p6 = _scan_code("$ROOT/$f", qr/(?<![\.])\.\.\.(?![\.])/ );
    ok(!@p6, "P6 - no yada-yada (...): $f");
    diag("  line $_->{line}: $_->{text}") for @p6;

    # P7: no \o{...}
    my @p7 = _scan_code("$ROOT/$f", qr/\\o\{/);
    ok(!@p7, "P7 - no \\o{} octal escape: $f");
    diag("  line $_->{line}: $_->{text}") for @p7;

    # P8: no \x{NNN} wide
    my @p8 = _scan_code("$ROOT/$f", qr/\\x\{[0-9a-fA-F]{3,}\}/);
    ok(!@p8, "P8 - no wide \\x{} hex escape: $f");
    diag("  line $_->{line}: $_->{text}") for @p8;

    # P9: no @- / @+ / $-[N] / $+[N]
    my @p9 = _scan_code("$ROOT/$f", qr/(?:\@-|\@\+|\$-\[|\$\+\[)/);
    ok(!@p9, "P9 - no \@-/\@+/\$-[N]/\$+[N] (5.6+ special vars): $f");
    diag("  line $_->{line}: $_->{text}") for @p9;
}

######################################################################
# P10-P14: .pm files only
######################################################################
for my $pm (@pm_files) {
    my $text = _slurp("$ROOT/$pm");

    # P10: $VERSION self-assignment
    ok($text =~ /\$VERSION\s*=\s*\$VERSION/,
       "P10 - \$VERSION self-assignment present: $pm");

    # P11: warnings stub
    ok($text =~ /\$INC\{'warnings\.pm'\}\s*=.*?eval\s*['"]package warnings;\s*sub import/s,
       "P11 - warnings compat stub present: $pm");

    # P12: CVE-2016-1238
    my $code = $text;
    $code =~ s/\n__END__\b.*\z//s;
    $code =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    ok($code =~ /BEGIN\s*\{[^}]*pop\s+\@INC[^}]*\}/s
    || $code =~ /pop \@INC if \$INC\[-1\] eq '\.'/ ,
       "P12 - CVE-2016-1238 pop \@INC in BEGIN: $pm");

    # P13: use 5.00503
    ok($text =~ /^use 5\.00503;/m,
       "P13 - use 5.00503 present: $pm");

    # P14: header order: use5 -> strict -> warnings_stub -> use warnings
    #                    -> pop @INC -> use vars -> $VERSION
    my %pos;
    for my $pair (
        [ 'use5',     qr/^use 5\.00503;/m                     ],
        [ 'strict',   qr/^use strict;/m                       ],
        [ 'wstub',    qr/\$INC\{'warnings\.pm'\}/             ],
        [ 'warnings', qr/^use warnings;/m                     ],
        [ 'popinc',   qr/pop\s+\@INC/                         ],
        [ 'usevars',  qr/^use vars\b/m                        ],
        [ 'version',  qr/^\$VERSION\s*=\s*'\d/m               ],
    ) {
        my ($name, $re) = @$pair;
        if ($text =~ $re) { $pos{$name} = length($`) }
        else              { $pos{$name} = 999999 }
    }
    my $p14 = $pos{use5}     < $pos{strict}
           && $pos{strict}   < $pos{wstub}
           && $pos{wstub}    < $pos{warnings}
           && $pos{warnings} < $pos{popinc}
           && $pos{popinc}   < $pos{usevars}
           && $pos{usevars}  < $pos{version};
    ok($p14, "P14 - header order "
           . "(use5..strict..warnings..pop\@INC..vars..\$VERSION): $pm");
}

END { end_testing() }
