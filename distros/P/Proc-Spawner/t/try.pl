use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../$_", 'lib', 'blib/arch';
use Proc::ShellSpawn;
# PARSER=small, base or large (default): which parser run() gets
my %P = (small => 'Proc::ShellSubset::Small', base => 'Proc::ShellSubset', large => 'Proc::ShellSubset::Large');
delete @ENV{split ' ', delete $ENV{TRY_HIDE} // ''};   # names the caller set only for the modules (large-subset-runcompare.pl -run: PROC_SPAWNER_MISSING)
my $pm = $P{$ENV{PARSER} // 'large'} // die "PARSER: small, base or large\n"; eval "require $pm; 1" or die $@;
$Proc::ShellSpawn::TRACE = sub { print STDERR "  # $_[0]\n" } if $ENV{TRACE} && $ENV{TRACE} ne 'dot';
if (my $bl = $ENV{RECBUILTIN}) {   # measurement (large-subset-runcompare.pl -q): log each builtin call: HANDLER \035 N=V \036 ... \035 ARGV joined by \037
  open my $bh, '>>', $bl or die "$bl: $!"; select((select($bh), $| = 1)[0]);
  $Proc::ShellSpawn::ONBUILTIN = sub { my ($h, $a, $e) = @_;
    print $bh join("\035", $h, join("\036", map "$_=$e->{$_}", sort keys %$e), join("\037", @$a)), "\n" } }
my $string = defined $ENV{TRY_FILE} ? do { open my $f, '<', delete $ENV{TRY_FILE} or die "TRY_FILE: $!"; binmode $f; local $/; <$f> } : shift;   # (Windows: Perl's
my ($st, $err) = Proc::ShellSpawn::run($string);                                                                              #  spawn mangles arguments)
defined $st or print(STDERR "outside the subset: $err->{error} at $err->{pos}\n"), exit 255;   # (as die did on Linux; die's status is $!, which varies)
if (my $s = $Proc::ShellSpawn::SIGNALLED) { local $SIG{$s} = 'DEFAULT'; kill $s, $$; sleep 1 }   # die by it, as sh -c would
exit $st;
