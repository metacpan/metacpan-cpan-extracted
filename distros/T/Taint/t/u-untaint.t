#! perl -Tw

# These are the tests which use 'unconditional_untaint'.

BEGIN {
    unshift @INC, '..' if -d '../t' and -e '../Taint.pm';
    unshift @INC, '.' if -d 't' and -e 'Taint.pm';
}

use strict;
my @warnings;

END { print "not ok\n", @warnings if @warnings }

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $^W = 1;
}

$| = 1;
require Taint;
if (&Taint::allowing_insanity) {
    # we're going to test
    print "1..10\n";
    unimport Taint 'sanity';
    import Taint qw/:ALL unconditional_untaint/;
} else {
    print "# Can't test action of unconditional_untaint - it's disabled!\n";
    # Just test that it fails to load
    eval {
	unimport Taint 'sanity';
    };
    if ($@ !~ /Disabled/) {
	print "1..1\nnot ok 1\n# Unexpected error: $@";
    } else {
	print "1..0\n";
    }
    exit;
}

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

my @foo = 1..10;
test 1, not any_tainted(@foo);
taint(@foo);
test 2, all_tainted(@foo);
unconditional_untaint($foo[4]);
test 3, not all_tainted(@foo);
test 4, any_tainted(@foo);
test 5, tainted( $foo[3]);
test 6, not is_tainted($foo[4]);
test 7, 9 == grep is_tainted($_), @foo;
test 8, all_tainted(@foo[0..3,5..9]);
unconditional_untaint(@foo);
test 9, not any_tainted(@foo);
test 10, not @warnings;
exit;
