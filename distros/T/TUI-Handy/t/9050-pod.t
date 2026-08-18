use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9050-pod.t - the module's POD is well-formed.  If Pod::Checker is
# available it is used; otherwise a lightweight structural check is run so
# the test still means something on a bare Perl 5.005_03.
#
# This is the distribution's own, stricter form of INA_CPAN_Check check_G,
# so t/9000-ina-cpan-check.t does not call check_G as well.

use lib 't/lib';
use INA_CPAN_Check;

my $file = 'lib/TUI/Handy.pm';

# The require is written on the eval line on purpose: pmake.bat collects a
# bare "require Foo" in a test file into build_requires, and Pod::Checker is
# optional here (it is not in the Perl 5.005_03 core).  Declaring it as a
# prerequisite would contradict the distribution's own minimum-perl claim.
my $have_checker = 0;
eval { require Pod::Checker; $have_checker = 1 };

# _slurp() comes from INA_CPAN_Check and returns '' for a file it cannot
# open, so every match below is safe without a defined() guard.
my $src = _slurp($file);

my @tests = (
    sub { ok(-f $file, "$file exists") },
    sub { ok(($src =~ /^=head1\s+NAME/m) ? 1 : 0, 'POD has =head1 NAME') },
    sub { ok(($src =~ /^=head1\s+SYNOPSIS/m) ? 1 : 0, 'POD has =head1 SYNOPSIS') },
    sub { ok(($src =~ /^=cut/m) ? 1 : 0, 'POD is terminated with =cut') },
    sub {
        # Balanced =over / =back.
        my $over = () = ($src =~ /^=over\b/mg);
        my $back = () = ($src =~ /^=back\b/mg);
        ok($over == $back, "=over ($over) balances =back ($back)");
    },
    sub {
        if ($have_checker) {
            my $checker = Pod::Checker->new();
            # File::Spec->devnull() is the portable bit bucket: /dev/null on
            # Unix, nul on Windows.  Writing to a literal 'nul' file name in
            # the working directory would silently discard the output but
            # leave a phantom entry on some Windows shells.
            require File::Spec;
            my $devnull = File::Spec->devnull();
            unless (open(NULL, ">$devnull")) {
                ok(0, "cannot open $devnull: $!");
                return;
            }
            $checker->parse_from_file($file, \*NULL);
            close NULL;
            ok($checker->num_errors() == 0,
               'Pod::Checker reports no errors (' . $checker->num_errors() . ')');
        }
        else {
            ok(1, 'Pod::Checker not installed - structural checks used');
        }
    },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
