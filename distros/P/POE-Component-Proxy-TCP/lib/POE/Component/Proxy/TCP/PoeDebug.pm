package POE::Component::Proxy::TCP::PoeDebug;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(set_level get_level dbprint
);

$VERSION = '0.01';

use POE;

# Debugging utils for proxy module tester
# Andrew V. Purshottam 17 Jun 2004
# to do:
# - evolve this into proper module with exporter and other crap (done)
# - create kind of shared poe utils for your poe stuff.
# - move design discussion and debugging levels into a POD
# - create symbolic constants for levels.

# dbprint is designed to run from inside or outside
# a poe session, with or without a $heap->{self}->{name}
# I really do not understand Perl and POE well enough
# to write a good debug print subroutine, if you have better one
# _that works nicely with POE sessions_, please
# mail it to me or submit it against this source
# as a feature improvement (once I get this crap up
# on source forge or similar.)

# debug levels
# -1 - not used as arg to dbprint, so used as debug level means print nothing ever.
# 0  - error, print even when not debugging
# 1  - lifecycle trace events, generally only happen once
# 2  - per "line" or user event type events
# 3  - repeated stuff that can happen many times per run
# 4  - per character or similar can happen lots of times (eg per char)
# 5-20  - tedious inner loop of algorithm or nasty dumps
# 100 - only turn on in emergency lots of crap, recursive dump of strutures

# dbprint($level_num, exp ...) - print debugging info
$main::debug_level = 0; # shutup by default.

sub set_level{
  my $level = shift;
  $main::debug_level = $level;
}

sub get_level {
  return $main::debug_level;
}


# dbprint($level, $string1, $String2, ...) print strings
# with helpful context prefix if $level <= $main::debug_level
sub dbprint {
  my $level = shift;
  return unless $level <= $main::debug_level;
  # yeah this context grabbing crap is awful, maybe someday
  # I will make more beautiful, or maybe a decent perl OO / introspection
  # system will make it unnecessary (as it is almost in python).
  my ($kernel, $session, $session_id, $alias, $heap, $self, $type, $name);
  my $info_string = "trace:";
  $kernel = $poe_kernel;
  if (defined $kernel) {
    $info_string = "POE trace:";
    $session = $kernel->get_active_session();
    if (defined $session) {
      $session_id = $session->ID;
      $info_string .= "ses:$session_id:";
      my @aliases = $kernel->alias_list( $session );
      if (@aliases) {
	$alias = $aliases[0];
	$info_string .= "$alias:";
      }
      $heap = $session->get_heap();
      if (defined $heap) {
	if (exists($heap->{self})) {
	  $self = $heap->{self}; 
	  $type = ref($self);
	  $info_string .= "$type:"; 
	  if (exists($self->{name})) {
	    $name = $self->{name};
	    $info_string .= "$name:";
	  }
	}
      }
    }
  } else {
    $info_string = "outside POE:";
  }
  print $info_string, " ";
  foreach my $x (@_) {
    print $x;
  }
  print "\n";

}

1;

__END__

=head1 PoeDebug

=cut
