######################################################################
#
# 9001-load.t
#
# SYNOPSIS
#   prove -l t/9001-load.t
#   perl t/9001-load.t
#
# DESCRIPTION
#   Verifies two things:
#
#   1. PSGI::Handy module family loads and exposes its interface
#      - Every module loads without error
#      - $VERSION is defined and looks like a version number
#      - Public methods exist (can() check)
#
#   2. INA_CPAN_Check library load and export
#      - t/lib/INA_CPAN_Check.pm loads without error
#      - check_A through check_K and helpers are defined
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

######################################################################
# Minimal TAP harness (local -- not imported from INA_CPAN_Check
# so that the counter is not reset when INA_CPAN_Check is loaded)
######################################################################

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

######################################################################
# Test plan
######################################################################

# package => [ methods to verify via can() ]
my @modules = (
    [ 'PSGI::Handy',
      [ qw(new renderer db config router route
           get post put patch del head any
           before after to_app) ] ],
    [ 'PSGI::Handy::Router',
      [ qw(new add match routes) ] ],
    [ 'PSGI::Handy::Request',
      [ qw(new method path query_string content_type content_length
           env header body
           param param_all param_names params cookie cookies) ] ],
    [ 'PSGI::Handy::Response',
      [ qw(new html text json redirect
           status set_status body set_body
           header set_header remove_header content_type cookie finalize) ] ],
    [ 'PSGI::Handy::Context',
      [ qw(new req app params param db config stash
           html text json redirect res render) ] ],
);

my $method_total = 0;
my $pair;
for $pair (@modules) { $method_total += scalar(@{ $pair->[1] }); }

my $total = scalar(@modules) * 2     # load + VERSION per module
          + $method_total            # can() checks
          + 4;                       # INA_CPAN_Check section
plan_tests($total);

######################################################################
# Section 1: PSGI::Handy family
######################################################################
for $pair (@modules) {
    my ($pkg, $methods) = @$pair;

    eval "require $pkg";
    ok(!$@, "$pkg loads without error");
    diag("load error: $@") if $@;

    my $ver = do { no strict 'refs'; ${"${pkg}::VERSION"} };
    ok(defined $ver && $ver =~ /^\d+\.\d+/,
       "$pkg: \$VERSION defined and well-formed");

    my $m;
    for $m (@$methods) {
        ok($pkg->can($m), "$pkg->can('$m')");
    }
}

######################################################################
# Section 2: INA_CPAN_Check
######################################################################
eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

ok( defined &INA_CPAN_Check::ok
 && defined &INA_CPAN_Check::plan_tests
 && defined &INA_CPAN_Check::_slurp
 && defined &INA_CPAN_Check::_slurp_lines
 && defined &INA_CPAN_Check::_scan_code,
   'INA_CPAN_Check: key helpers defined');

ok( defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_B
 && defined &INA_CPAN_Check::check_C && defined &INA_CPAN_Check::check_D
 && defined &INA_CPAN_Check::check_E && defined &INA_CPAN_Check::check_F
 && defined &INA_CPAN_Check::check_G && defined &INA_CPAN_Check::check_H
 && defined &INA_CPAN_Check::check_I && defined &INA_CPAN_Check::check_J
 && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');

ok( defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_B
 && defined &INA_CPAN_Check::count_C && defined &INA_CPAN_Check::count_D
 && defined &INA_CPAN_Check::count_E && defined &INA_CPAN_Check::count_F
 && defined &INA_CPAN_Check::count_G && defined &INA_CPAN_Check::count_H
 && defined &INA_CPAN_Check::count_I && defined &INA_CPAN_Check::count_J
 && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');
