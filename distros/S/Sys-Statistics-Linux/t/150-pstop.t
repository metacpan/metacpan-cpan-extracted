use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

for my $f ("/proc/$$/stat","/proc/$$/statm","/proc/$$/status","/proc/$$/cmdline","/proc/$$/wchan") {
    if (!-r $f) {
        plan skip_all => "$f is not readable";
        exit(0);
    }
}

my $sys = Sys::Statistics::Linux->new();
$sys->set(processes => 1);
sleep 1;
my $stat = $sys->get;

if (!scalar keys %{$stat->processes}) {
    plan skip_all => "processlist is empty";
    exit(0);
}

plan tests => 1;

my @top   = $stat->pstop( ttime => 5 );
my $count = scalar keys %{ $stat->{processes} };

# maybe the user has no rights to read /proc/<pid>
if ($count > 5) {
    $count = 5;
}

ok(@top == $count, "checking psfind");
