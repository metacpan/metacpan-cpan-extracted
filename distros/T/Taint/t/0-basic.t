#! perl -Tw

BEGIN {
    unshift @INC, '..' if -d '../t' and -e '../Taint.pm';
    unshift @INC, '.' if -d 't' and -e 'Taint.pm';
}

# These are the basic taint utility checks.

print "1..52\n";

use strict;
use vars qw(@warnings);

END { # catch compilation-time errors
    return unless @warnings;
    print "not ok\n# uncaught warnings: @warnings\n"
};

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $^W = 1;
}

######################### We have some black magic to print on failure.

BEGIN { $| = 1 }
use vars qw($loaded);
END {print "not ok 1\n" unless $loaded;}
use Taint;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use Taint qw(:ALL);

sub test ($$;$) {
    my($num, $bool, $diag) = @_;
    if ($bool) {
	print "ok $num\n";
	return;
    }
    print "not ok $num\n";
    return unless defined $diag;
    $diag =~ s/\Z\n?/\n/;			# unchomp
    print map "# $num : $_", split m/^/m, $diag;
}

test 2, $Taint::VERSION > 0.08;

my $foo = "bar";
test 3, not is_tainted $foo;
test 4, not any_tainted $foo;
test 5, not all_tainted $foo;

my @foo = qw(this is a test);
test 6, not any_tainted @foo;
test 7, not all_tainted @foo;

push @foo, tainted_null;
test 8, any_tainted @foo;
test 9, not all_tainted @foo;

$foo = pop @foo;
test 10, is_tainted $foo;
test 11, any_tainted $foo;
test 12, all_tainted $foo;

test 13, not any_tainted @foo;
test 14, not all_tainted @foo;

taint @foo;
test 15, (any_tainted @foo), join "\n", map "'$_'", @foo;
test 16, all_tainted @foo;

test 17, all_tainted tainted_null, tainted_zero;

# Checking taint and the proto on is_tainted
my @bar = 1..10;
$bar[3] = undef;
taint @bar;
@foo = grep is_tainted $_, @bar;
test 18, @foo == 9;

$foo = 12345;
taint($foo);
test 19, ($foo == 12345 and is_tainted $foo);

# How about untainting the wrong way?
test 20, not defined &untaint;
$foo = tainted_null;
test 21, is_tainted $foo;
Taint::unconditional_untaint $foo;
test 22, is_tainted $foo;
$_ = shift @warnings;
test 23, /sub unconditional_untaint\(\) not properly imported/, "'$_'";
test 24, not is_tainted $_;

test 25, taint_checking;

{
    $Taint::DEBUGGING = 1;
    my $sub = make_extractor '(\d+)\s+\d+\s+(\d+)';
    $Taint::DEBUGGING = 0;
    my $foo = shift @warnings;
    test 26, index($foo, '/(\d+)\s+\d+\s+(\d+)/') != -1, $foo;
    my @foo = &$sub('123 456 789');
    test 27, join("#", @foo) eq "123#789";
    test 28, @foo == 2, join ', ', map "'$_'", @foo;
    @foo = &$sub('123 456');
    test 29, @foo == 0;
    test 30, &$sub('123 456 789') == '123';
    test 31, not defined &$sub('123 456');
    $sub = eval { make_extractor ')bad pattern(' };
    test 32, $@ =~ /unmatched/, "'$@'";
    test 33, not defined $sub;
}

{
    my $sub = make_extractor '^(\w+)';
    my @foo = &$sub(qw/foo -bar baz/);
    test 34, join("!", map { defined $_ ? $_ : '[undef]' } @foo)
	eq "foo!baz";
    test 35, @foo == 2;
    $sub = make_extractor '(f\w*)|(b\w*)';
    @foo = &$sub(qw/foo bar/);
    test 36, join("#", map { defined $_ ? $_ : '[undef]' } @foo)
	eq "foo#[undef]#[undef]#bar";
    test 37, @foo == 4;
}

eval 'sub tainted_null () { "" }';
$foo = shift @warnings;
test 38, $foo =~ /Constant subroutine \w+ redefined/, $foo;

eval 'sub tainted_zero () { 0 }';
$foo = shift @warnings;
test 39, $foo =~ /Constant subroutine \w+ redefined/, $foo;

eval 'sub taint_checking () { 1 }';
$foo = shift @warnings;
test 40, $foo =~ /Constant subroutine \w+ redefined/, $foo;

$foo = 'ImPrObAbLe';
taint($foo);
test 41, ($foo eq 'ImPrObAbLe' and is_tainted $foo), $foo;

{
    my $foo = 10; my $bar = 12;
    taint($foo, $bar);
    test 42, (($foo ^ $bar) == 6), 'stringified';
    $foo = '10'; $bar = '12';
    taint($foo, $bar);
    test 43, (($foo ^ $bar) eq "\0\2"), 'numified';
}

{
    my $foo = 1234;
    taint $foo;
    test 44, is_tainted taintedness $foo;
    test 45, not is_tainted taintedness 1234;
    test 46, (taintedness($foo) eq '' and taintedness(1234) eq '');
}

{
    my %foo = qw(fred 3 barney 5);
    taint $foo{fred};
    test 47, tainted %foo;
    test 48, any_tainted %foo;
    $foo{fred}++;
    test 49, is_tainted $foo{fred};
    $foo{fred} = 0;
    test 50, not any_tainted %foo;
}

# # # # # # # # # # # # final tests # # # # # # # # #

# Ensure that none of that turned off warnings!
test 51, $^W;

test 52, (not @warnings), join ', ', map "$_: '$warnings[$_]'", 0..$#warnings;
@warnings = ();

exit;
