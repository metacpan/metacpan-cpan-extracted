package TestUtil;
use Exporter 'import';

our @EXPORT = qw(
    expected_assert
    expected_assert_bin
);

use Test2::V0;

use constant HAS_36 => $] >= 5.036;

sub expected_assert {
    my ($expr) = @_;

    my $m = match qr/\AAssertion failed \($expr\)/;

    if (HAS_36) {
        return $m;
    }

    # Workaround to less than 5.36

    if ($expr eq 'true')  { $expr = 1 if !HAS_36 }
    if ($expr eq 'false') { $expr = "" if !HAS_36 }

    my $m1 = match qr/\AAssertion failed \($expr\)/;
    my $m2 = match qr/\AAssertion failed \("$expr"\)/;
    return in_set($m, $m1, $m2);
}

sub expected_assert_bin {
    my ($left, $op, $right) = @_;

    my $m = match qr/\AAssertion failed \($left $op $right\)/;

    if (HAS_36) {
        return $m;
    }

    # Workaround to less than 5.36

    if ($left eq 'true')  { $left = 1 if !HAS_36 }
    if ($left eq 'false') { $left = "" if !HAS_36 }

    my $m1 = match qr/\AAssertion failed \($left $op $right\)/;
    my $m2 = match qr/\AAssertion failed \("$left" $op $right\)/;
    my $m3 = match qr/\AAssertion failed \("$left" $op "$right"\)/;
    return in_set($m, $m1, $m2, $m3);
}

1;
