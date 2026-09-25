use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# generate_cdi_specs against a scripted host (karr #63). t/60 tests the pure
# managed-source decision; this pins the commands on either side of it
# (goldens under t/golden/cdi/).
#
# CLAIMS:
#   * managed (nvidia-cdi-refresh.path installed, or a /run/cdi/nvidia.yaml
#     from another producer) => `systemctl start nvidia-cdi-refresh.service`,
#     no mkdir, no `nvidia-ctk cdi generate`;
#   * unmanaged (unit disabled/not-found, inactive, no /run/cdi file) =>
#     `mkdir -p /etc/cdi`, then `nvidia-ctk cdi generate`, in that order, and
#     no systemctl start.
#
# NOT covered -- a green prove is NOT evidence CDI works: whether
# nvidia-ctk enumerates the GPUs, what nvidia-cdi-refresh writes, whether
# the device plugin loads nvidia.com/gpu once. The systemctl outputs are
# hand-written. A maintainer confirms on a real node with the toolkit
# installed: generate_cdi_specs, then `nvidia-ctk cdi list` and
# `ls /etc/cdi /run/cdi`.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile );
use Rex::GPU::NVIDIA;

my $ENABLED = 'systemctl is-enabled nvidia-cdi-refresh.path 2>/dev/null';
my $ACTIVE  = 'systemctl is-active nvidia-cdi-refresh.path 2>/dev/null';
my $RUN_CDI = 'test -f /run/cdi/nvidia.yaml';

sub cdi_on {
  my ( @responses ) = @_;
  return record_host(
    host => host_profile('debian-12', responses => \@responses),
    code => sub { Rex::GPU::NVIDIA::generate_cdi_specs() }
  );
}

my @PROBES = ( "run: $ENABLED", "run: $ACTIVE", "run: $RUN_CDI" );

subtest 'managed: refresh unit installed => start it, no cdi generate' => sub {
  my $rec = cdi_on(
    [ $ENABLED => 'static', 0 ],
    [ $ACTIVE  => 'inactive', 3 ],
    [ $RUN_CDI => '', 1 ]
  );
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES,
    'run: systemctl start nvidia-cdi-refresh.service 2>/dev/null'
  ], 'the three probes, then systemctl start');
  ok(!(grep { /cdi generate|mkdir/ } @{ $rec->{lines} }), 'no mkdir, no nvidia-ctk cdi generate');
  golden_is($rec, 'cdi/managed');
};

subtest 'managed: only a /run/cdi/nvidia.yaml => start, no cdi generate' => sub {
  my $rec = cdi_on(
    [ $ENABLED => 'not-found', 4 ],
    [ $ACTIVE  => 'inactive', 3 ],
    [ $RUN_CDI => '', 0 ]
  );
  is($rec->{error}, undef, 'no die');
  is($rec->{lines}[-1], 'run: systemctl start nvidia-cdi-refresh.service 2>/dev/null', 'systemctl start');
  ok(!(grep { /cdi generate|mkdir/ } @{ $rec->{lines} }), 'no mkdir, no nvidia-ctk cdi generate');
};

subtest 'unmanaged => mkdir, then nvidia-ctk cdi generate' => sub {
  my $rec = cdi_on(
    [ $ENABLED => 'disabled', 1 ],
    [ $ACTIVE  => 'inactive', 3 ],
    [ $RUN_CDI => '', 1 ]
  );
  is($rec->{error}, undef, 'no die');
  is_deeply($rec->{lines}, [
    @PROBES,
    'run: mkdir -p /etc/cdi',
    'run: nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null'
  ], 'the probes, mkdir, then cdi generate -- in that order');
  ok(!(grep { /systemctl start/ } @{ $rec->{lines} }), 'no systemctl start');
  golden_is($rec, 'cdi/unmanaged');
};

done_testing;
