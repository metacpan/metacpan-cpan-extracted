#! perl -w

# These are the tests of what happens if taint checks are
# not turned on.
# They could be kept in the same file with the others, but
# that would take the ability to do set-id stuff.

BEGIN {
    unshift @INC, '..' if -d '../t' and -e '../Taint.pm';
    unshift @INC, '.' if -d 't' and -e 'Taint.pm';
}

use strict;
use vars qw(@warnings);

END { print "not ok\n", @warnings if @warnings }

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $^W = 1;
}

print "1..4\n";

use Taint qw(allow_no_taint :ALL);

sub test ($$;$) {
    my($num, $bool, $diag) = @_;
    if ($bool) {
	print "ok $num\n";
	return;
    }
    print "not ok $num\n";
    return unless defined $diag;
    $diag =~ s/\Z\n?/\n/;	# unchomp
    print map "# $num : $_", split m/^/m, $diag;
}

test 1, not taint_checking;
my $foo = tainted_null;
test 2, not is_tainted($foo);
test 3, not any_tainted(tainted_null, tainted_zero);
test 4, not is_tainted taintedness tainted_null;

exit;
