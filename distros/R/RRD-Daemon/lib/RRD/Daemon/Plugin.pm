package RRD::Daemon::Plugin;

# base class for RRD plugins

# pragmata ----------------------------

use strict;
use warnings;

use Carp  qw( confess );
use charnames  qw( :full );
# constants ---------------------------

# you may need binmode STDOUT, ':utf8' to print this correctly
use constant RRDP_UNIT_TEMP_C => \"\N{DEGREE SIGN}C";
my $PACKAGE = __PACKAGE__;
# methods --------------------------------------------------------------------

sub new       { bless +{}, $_[0] }
# __PACKAGE__ will not interpolate directly
sub name      { (my $n = ref $_[0] || $_[0]) =~ s/^${PACKAGE}:://o; $n }
sub shortname { (my $n = lc $_[0]->name) =~ s/::/_/; $n }
sub min       { 0 }
sub max       { 'U' }
sub ds_type   { 'GAUGE' }
sub interval  { confess 'abstract method call' }

# -------------------------------------

sub keys      { 
  my $vs = $_[0]->read_values;

  until ( keys %$vs ) {
    warn "sleeping waiting for values from $_[0]";
    sleep 1;
    $vs = $_[0]->read_values;
  }

  [ keys %$vs ];
}

# ----------------------------------------------------------------------------

1; # keep require happy
