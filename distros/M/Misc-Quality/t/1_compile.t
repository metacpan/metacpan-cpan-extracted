
# This test simply loads all the modules
# it does this by scanning the directory for .pm files
# and use'ing each in turn

# It is slow because of the fork required for each separate use
use 5.006;
use strict;
use warnings;

# Test module only used for planning
# Note that we can not use Test::More since Test::More
# will lose count of its tests and complain (through the fork)
use Test;

use File::Find;

our @modules;

# If SKIP_COMPILE_TEST environment variable is set we
# just skip this test because it takes a long time
if (exists $ENV{SKIP_COMPILE_TEST}) {
  print "1..0 # Skip compile tests not required\n";
  exit;
}


# Scan the blib/ directory looking for modules


find({ wanted => \&wanted,
       no_chdir => 1,
       }, "blib");

# Start the tests
plan tests => (scalar(@modules));


# Loop through each module and try to run it

$| = 1;

for my $module (@modules) {

  # Try forking. Perl test suite runs 
  # we have to fork because each "use" will contaminate the 
  # symbol table and we want to start with a clean slate.
  my $pid;
  if ($pid = fork) {
    # parent

    # wait for the forked process to complet
    waitpid($pid, 0);

    # Control now back with parent.

  } else {
    # Child
    die "cannot fork: $!" unless defined $pid;

    my $not = '';

    eval "use $module ();";
    if( $@ ) {
      warn "require failed with '$@'\n";
      $not = 'not ';
    }
    # Combine $not with the single print since some OSes do
    # insert automatic new lines
    print $not ."ok - $module\n";
    # Must remember to exit from the fork
    exit;
  }
}



# We do this as a separate process else we'll blow the hell
# out of our namespace.
sub compile_module {
    my ($module) = $_[0];
    return scalar `$^X "-Ilib" t/lib/compmod.pl $module` =~ /^ok/;
}



# This determines whether we are interested in the module
# and then stores it in the array @modules

sub wanted {
  my $pm = $_;

  # is it a module
  return unless $pm =~ /\.pm$/;

  # Remove the blib/lib (assumes unix!)
  $pm =~ s|^blib/lib/||;

  # Translate / to ::
  $pm =~ s|/|::|g;

  # Remove .pm
  $pm =~ s/\.pm$//;

  push(@modules, $pm);
}
