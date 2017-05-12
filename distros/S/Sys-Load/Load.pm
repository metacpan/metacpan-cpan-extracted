
package Sys::Load;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw( getload uptime );

our $VERSION = '0.2';

bootstrap Sys::Load $VERSION;

# Preloaded methods go here.

use constant UPTIME => "/proc/uptime";

sub uptime {
  open(FILE, UPTIME) || return 0;
  my $line = <FILE>;
  my($uptime, $idle) = split /\s+/, $line;
  close FILE;
  return $uptime;
}

1;

__END__

=head1 NAME

Sys::Load - Perl module for getting the current system load and uptime

=head1 SYNOPSIS

  use Sys::Load qw/getload uptime/;
  print "System load: ", (getload())[0], "\n";
  print "System uptime: ", int uptime(), "\n";

=head1 DESCRIPTION

getload() returns 3 elements: representing load averages over the last 1, 5 and
15 minutes. On failure empty list is returned.

uptime() returns the system uptime in seconds. Returns 0 on failure.

=head2 EXPORT

None by default.

=head1 AUTHOR

Peter BARABAS, E<lt>z0d [@] artifact [.] huE<gt>

=head1 SEE ALSO

L<getloadavg(3)>, L<uptime(1)>

=cut

