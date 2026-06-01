######################################################################
#
# check_compatibility.pl
#
# Demonstrates Perl500503Syntax::OrDie programmatic API.
# Checks a given Perl source file or inline code for
# Perl 5.005_03 compatibility violations.
#
# Usage:
#   perl eg/check_compatibility.pl script.pl
#   perl eg/check_compatibility.pl  (runs built-in examples)
#
# Demonstrates: check_file, check_source
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use FindBin ();
use lib "$FindBin::Bin/../lib";

use Perl500503Syntax::OrDie ();

my $banner = '-' x 60;

if (@ARGV) {
    # Check a file given on the command line
    my $file = $ARGV[0];
    print "$banner\n";
    print "Checking: $file\n";
    print "$banner\n";
    eval { Perl500503Syntax::OrDie::check_file($file) };
    if ($@) {
        print $@;
        exit 1;
    }
    print "No violations found.\n";
    exit 0;
}

# Built-in demonstration
print "Perl500503Syntax::OrDie v$Perl500503Syntax::OrDie::VERSION demo\n";
print "$banner\n";

# Example 1: clean Perl 5.005_03-compatible code
my $clean = <<'CODE';
use strict;
use vars qw($x @items %data);
$x = 42;
open(FH, ">output.txt") or die $!;
print FH "$x\n";
close FH;
mkdir("newdir", 0755) or die $!;
CODE

print "Example 1: valid Perl 5.005_03 code\n";
{
    my @v = Perl500503Syntax::OrDie::check_source($clean, 'example1');
    if (@v) {
        print "  -> UNEXPECTED violation:\n";
        print "     $_\n" for @v;
    }
    else {
        print "  -> No violations. OK\n";
    }
}
print "\n";

# Example 2: code using 'our' (Perl 5.6 feature)
# (string built at runtime to avoid selfcheck false-positive)
my $bad_our = 'ou' . 'r $config = {};' . "\n"
            . 'ou' . 'r @items  = (1, 2, 3);' . "\n";

print "Example 2: 'our' declaration (Perl 5.6+)\n";
{
    my @v = Perl500503Syntax::OrDie::check_source($bad_our, 'example2');
    if (@v) {
        print "  -> $_" for map { (my $m=$_)=~s/\s+\z//; "$m\n" } @v;
    }
    else {
        print "  -> (not detected)\n";
    }
}
print "\n";

# Example 3: defined-or-assign (Perl 5.10 feature)
# (string built at runtime to avoid selfcheck false-positive)
my $bad_defor = 'my $value = undef;' . "\n"
              . '$value ' . join('', '/', '/') . "= 'default';\n";

print "Example 3: defined-or-assign (Perl 5.10+)\n";
{
    my @v = Perl500503Syntax::OrDie::check_source($bad_defor, 'example3');
    if (@v) {
        print "  -> $_" for map { (my $m=$_)=~s/\s+\z//; "$m\n" } @v;
    }
    else {
        print "  -> (not detected)\n";
    }
}
print "\n";

# Example 4: say (Perl 5.10 feature)
# (string built at runtime to avoid selfcheck false-positive)
my $bad_say = 'use feature ' . "'" . 'say' . "'" . ';' . "\n"
            . 'sa' . 'y "Hello, world!";' . "\n";

print "Example 4: 'say' and 'use feature' (Perl 5.10+)\n";
{
    my @v = Perl500503Syntax::OrDie::check_source($bad_say, 'example4');
    if (@v) {
        print "  -> $_" for map { (my $m=$_)=~s/\s+\z//; "$m\n" } @v;
    }
    else {
        print "  -> (not detected)\n";
    }
}
print "\n";

print "$banner\n";
print "Demo complete.\n";

