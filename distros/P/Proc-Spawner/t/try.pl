use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../$_", 'lib', 'blib/arch';
use Proc::ShellSpawn;
# PARSER=small, base or large (default): which parser run() gets
my %P = (small => 'Proc::ShellSubset::Small', base => 'Proc::ShellSubset', large => 'Proc::ShellSubset::Large');
my $pm = $P{$ENV{PARSER} // 'large'} // die "PARSER: small, base or large\n"; eval "require $pm; 1" or die $@;
$Proc::ShellSpawn::TRACE = sub { print STDERR "  # $_[0]\n" } if $ENV{TRACE} && $ENV{TRACE} ne 'dot';
my ($st, $err) = Proc::ShellSpawn::run(shift);
defined $st or die "outside the subset: $err->{error} at $err->{pos}\n";
if (my $s = $Proc::ShellSpawn::SIGNALLED) { local $SIG{$s} = 'DEFAULT'; kill $s, $$; sleep 1 }   # die by it, as sh -c would
exit $st;
