######################################################################
#
# 9050-pod.t  POD structure and content checks
#
# G1:  =head1 NAME present
# G2:  =head1 VERSION present
# G3:  =head1 SYNOPSIS present
# G4:  =head1 DESCRIPTION present
# G5:  =head1 DIAGNOSTICS present
# G6:  =head1 CHECKED CONSTRUCTS present
# G7:  =head1 COMPATIBILITY present
# G8:  =head1 LIMITATIONS present
# G9:  =head1 SEE ALSO present
# G10: =head1 AUTHOR present
# G11: =head1 LICENSE present
# G12: Pod::Checker (skip if Pod::Checker < 1.51)
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
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my $pm = "$ROOT/lib/Perl500503Syntax/OrDie.pm";
plan_skip('primary .pm not found') unless -f $pm;

# Check Pod::Checker availability and version
my $pod_checker_ver = 0;
eval { require Pod::Checker; $pod_checker_ver = $Pod::Checker::VERSION || 0 };

plan_tests(13);

my $src = _slurp($pm);
my $rel = 'lib/Perl500503Syntax/OrDie.pm';

ok($src =~ /^=head1\s+NAME\b/m,             "G1: =head1 NAME in $rel");
ok($src =~ /^=head1\s+VERSION\b/m,          "G2: =head1 VERSION in $rel");
ok($src =~ /^=head1\s+SYNOPSIS\b/m,         "G3: =head1 SYNOPSIS in $rel");
ok($src =~ /^=head1\s+DESCRIPTION\b/m,      "G4: =head1 DESCRIPTION in $rel");
ok($src =~ /^=head1\s+DIAGNOSTICS\b/m,      "G5: =head1 DIAGNOSTICS in $rel");
ok($src =~ /^=head1\s+CHECKED CONSTRUCTS\b/m,"G6: =head1 CHECKED CONSTRUCTS in $rel");
ok($src =~ /^=head1\s+COMPATIBILITY\b/m,    "G7: =head1 COMPATIBILITY in $rel");
ok($src =~ /^=head1\s+LIMITATIONS\b/m,      "G8: =head1 LIMITATIONS in $rel");
ok($src =~ /^=head1\s+SEE ALSO\b/m,         "G9: =head1 SEE ALSO in $rel");
ok($src =~ /^=head1\s+AUTHOR\b/m,           "G10: =head1 AUTHOR in $rel");
ok($src =~ /^=head1\s+LICENSE\b/m,          "G11: =head1 LICENSE in $rel");

# G12: Pod::Checker errors check (skip if Pod::Checker < 1.51)
# G13: Pod::Checker warnings check (skip if Pod::Checker < 1.60)
my ($errors, $warnings) = (0, 0);
if ($pod_checker_ver && $pod_checker_ver >= 1.51) {
    my $checker = Pod::Checker->new(-warnings => 2);
    eval {
        # Two incompatible Pod::Checker families ship across Perls:
        #   * Pod::Simple-based (>= 1.73, Perl 5.26+) provides parse_file().
        #   * Pod::Parser-based (1.45 .. 1.71, Perl <= 5.24) provides only
        #     parse_from_file(), and writes its messages to STDOUT by
        #     default -- which would corrupt the TAP stream -- so the
        #     second argument explicitly redirects them to STDERR.
        # Calling parse_file() on the Pod::Parser-based versions throws
        # "Can't locate object method parse_file", which previously made
        # this test fail on every Perl from 5.16 through 5.24.
        if ($checker->can('parse_file')) {
            $checker->parse_file($pm);
        }
        else {
            $checker->parse_from_file($pm, \*STDERR);
        }
        $errors   = $checker->num_errors();
        $warnings = $checker->num_warnings();
    };
    $errors = -1 if $@;
    ok($errors == 0, "G12: Pod::Checker reports no errors in $rel");
    diag("Pod::Checker errors: $errors") if $errors;
}
else {
    ok(1, "G12: Pod::Checker skipped (version $pod_checker_ver < 1.51)");
}
if ($pod_checker_ver && $pod_checker_ver >= 1.60) {
    ok($warnings == 0, "G13: Pod::Checker reports no warnings in $rel");
    diag("Pod::Checker warnings: $warnings") if $warnings;
}
else {
    ok(1, "G13: Pod::Checker skipped (version $pod_checker_ver < 1.60)");
}

