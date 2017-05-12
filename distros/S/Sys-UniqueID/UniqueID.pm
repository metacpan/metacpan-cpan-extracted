=head1 NAME

Sys::UniqueID - Get a guaranteed unique identifier.

Great for generating database keys, temporary filenames,
and even gets out those tough grass stains!

=head1 SYNOPSIS

  use Sys::UniqueID;
  $id= uniqueid;

=head1 AUTHOR

v, E<lt>v@rant.scriptmania.comE<gt>

=head1 SEE ALSO

perl(1), Sys::HostIP

=cut

package Sys::UniqueID;
use strict;
use Sys::HostIP;
use vars qw($VERSION @ISA @EXPORT);
use vars qw($netaddr $idnum);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(uniqueid);
$VERSION = '1.0';

sub uniqueid()
{
  # absolutely ensure that id is unique: < 0x10000/second
  unless(++$idnum < 0x10000) { sleep 1; $idnum= 0; }
  return sprintf '%012X.%s.%08X.%04X', time, $netaddr, $$, $idnum;
}

$netaddr= sprintf '%02X%02X%02X%02X', (split /\./, hostip);
