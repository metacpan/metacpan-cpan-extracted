package RRD::Daemon::Plugin::HDDTemp;

# methods for reading from sensors -A for prrd

# pragmata ----------------------------

use feature qw( :5.10 );
use strict;
use warnings;

# inheritance -------------------------

use base qw( RRD::Daemon::Plugin );

# utility -----------------------------

use IPC::System::Simple  qw( capturex );
use List::MoreUtils      qw( part uniq zip );

use RRD::Daemon::Util  qw( warn trace tdump );

# constants ---------------------------

# methods --------------------------------------------------------------------

sub new {
  $_[0]->SUPER::new(@_[1..$#_]);
}

my $rootcheck = 0;
sub read_values {
  die "HDDTemp plugin uses hdparm, you need to be root to run\n"
    unless $rootcheck or 'root' eq getpwuid $>;

  $rootcheck = 1;

  my @devs = sort uniq map m!^/dev/([a-z]+)\d+\s! ? $1 : (), capturex 'mount';
  my @hdparm = capturex('hdparm', -C => map "/dev/$_", @devs);

  my %devstate = map +($_=>1), @devs;
  my $device;
 LINE:
  for my $i (0..$#hdparm) {
    given ($hdparm[$i]) {
      when ( /^\s*$/ ) { }

      when ( m!^/dev/(\w+):$! ) { $device = $1 }

      when ( m!^\s*drive state is:\s*(?<state>active/idle|standby)\s*$! ) {
        warn "no device seen before state at hdparm line $i\n"
          unless defined $device;
        $devstate{$device} = $+{state};
        $device = undef;
      } 

      default { warn "hdparm output line >>$_<< unparsed\n" }
    }
  }

  my ($sleep, $live) = part { $devstate{$_} eq 'active/idle' } keys %devstate;

  my @cmd = ('hddtemp', '-n', -u => 'C', map "/dev/$_", @$live);
  chomp(my @hddtemp = capturex(@cmd));
  die
    sprintf "failed to find data for correct drives (got %d, expected %d)\n",
            map 0+ @$_, \( @$live, \@hddtemp )
    unless @$live == @hddtemp;
  my %hddtemp = zip @$live, @hddtemp;
  $hddtemp{$_} = 'U' 
    for @$sleep;
  tdump devstate => \%devstate, live     => $live,     sleep => $sleep,
        cmd      => \@cmd,      hddtemp  => \%hddtemp,
     ;

  return \%hddtemp;
}

# -------------------------------------

sub interval { 120 }

# ----------------------------------------------------------------------------
1; # keep require happy
