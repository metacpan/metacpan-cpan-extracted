use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# install_container_toolkit on an OS it has no install path for (karr #63).
#
# CLAIM: the OS family is decided from the OS name alone, before any host
# interaction: an OS that is neither Debian, RedHat, SuSE nor a named RHEL
# rebuild dies with "Unsupported OS for NVIDIA Container Toolkit: <os>" and
# no run/pkg/file/can_run call was made.
#
# NOT covered: what Rex names a real host of these OSes (the names are
# hand-picked, not Rex output from a real Gentoo/Arch/FreeBSD host).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile );
use Rex::GPU::NVIDIA;

for my $os (qw( Gentoo Arch FreeBSD NixOS )) {
  my $rec = record_host(
    host => host_profile('debian-12', os => $os),
    code => sub { Rex::GPU::NVIDIA::install_container_toolkit() }
  );
  is($rec->{error}, "Unsupported OS for NVIDIA Container Toolkit: $os", "'$os': dies naming the OS");
  is_deeply($rec->{lines}, [], "'$os': no host command");
}

done_testing;
