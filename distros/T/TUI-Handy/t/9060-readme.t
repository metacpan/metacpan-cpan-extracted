use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9060-readme.t - the README stays consistent with the distribution: it
# names the module, states the current $VERSION, and mentions the author.
#
# This is the distribution's own, stricter form of INA_CPAN_Check check_H,
# so t/9000-ina-cpan-check.t does not call check_H as well.

use lib 't/lib';
use INA_CPAN_Check;

# _slurp() and _pm_version() come from INA_CPAN_Check.  _slurp() returns ''
# for a file it cannot open, so the matches below need no defined() guard.
my $readme = _slurp('README');

my $version = _pm_version('lib/TUI/Handy.pm');
$version = '' unless defined $version;

my @tests = (
    sub { ok(length($readme) > 0, 'README is present and non-empty') },
    sub { ok(($readme =~ /TUI::Handy/) ? 1 : 0, 'README names the module') },
    sub { ok($version ne '', 'module $VERSION was found') },
    sub {
        # The DEPENDENCIES section should mention the minimum Perl.
        ok(($readme =~ /5\.00503|5\.005_03/) ? 1 : 0,
           'README states the minimum Perl');
    },
    sub { ok(($readme =~ /ina\.cpan\@gmail\.com/) ? 1 : 0,
             'README carries the author e-mail') },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
