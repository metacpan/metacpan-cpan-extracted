package RRD::Daemon::Plugin::LMSensors;

# methods for reading from sensors -A for prrd

# pragmata ----------------------------

use feature qw( :5.10 );
use strict;
use warnings;

# inheritance -------------------------

use base qw( RRD::Daemon::Plugin );

# utility -----------------------------

use FindBin        qw( $Bin );
use Log::Log4perl  qw( );

use lib  "$Bin/perllib";
use RRD::Daemon::Util  qw( trace );

# constants ---------------------------

# methods --------------------------------------------------------------------

# read output of sensors -A (motherboard sensors, from lm_sensors package;
# -A suppresses info about the adapters used); return a hashref

sub read_values {
  chomp(my @sensors = qx( sensors -A ));
  my %sensors;
  my ($name, $temp);
  for my $line (@sensors) {
    my $degree_sym = qr/\302\260/;
    if ( ($name,$temp) =
         ($line =~ /^([\w ]+):\s*\+([\d.]+)${degree_sym}C/) ) {
      # massage name to work with RRD
      $name =~ tr! !!d;
      $sensors{$name} = $temp;
    } else {
      trace("ignoring '$line'");
    }
  }

  return \%sensors;
}

# -------------------------------------

sub interval { 10 }

# ----------------------------------------------------------------------------
1; # keep require happy
