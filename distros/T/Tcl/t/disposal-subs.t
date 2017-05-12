# see how CODE REFs are created and then freed

use Tcl;

$| = 1;

print "1..2\n";

my $int = Tcl->new;

$int->call('after', 1000, sub {"foo, bar, fluffy\n";});

my $q = 0;
for (1 .. 1000) {
    my $r = 'aaa';
    $int->call('after', 1000, sub {"*";});
    $int->call('after', 1000, sub {$r++;"$r#";});

    $int->call('if', 1000, sub {
	$r++;
	$q++;
    });
}

$int->icall('after', 3000, 'set var fafafa');
$int->icall('vwait', 'var'); # will wait for 3 seconds

# we have a number of commands created in Tcl, '::perl' package,
# but they must have been disposed.
my @p1 = $int->icall('info', 'commands', '::perl::*');
print STDERR "[[@p1; $r]]\n";

print +($#p1>10?"not ":""), "ok 1\n";

for (1 .. 1000) {
    my $r = 'aaa';
    $int->call('after', 1000, sub {"*";});
    $int->call('after', 1000, sub {$r++;"$r#";});

    $int->call('if', 1000, sub {
	$r++;
	$q++;
    });
}
$int->icall('after', 300, 'set var fafafa');
$int->icall('vwait', 'var'); # will wait for 0.3 seconds; will still have procs
my @p2 = $int->icall('info', 'commands', '::perl::*');
print +($#p2<10?"not ":""), "ok 2\n";

# now we finish and procs destroyed on cleanup

