use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# verify_nvidia / verify_nvidia_driver against a scripted host (karr #63).
#
# CLAIMS:
#   * module loaded, nvidia-smi lists a GPU, nvidia-ctk on PATH =>
#     verify_nvidia returns 1 and warns nothing;
#   * the same without nvidia-ctk => 0, a toolkit warning plus the summary;
#   * module loaded, nvidia-smi lists a GPU, libcuda.so.1 in the linker cache
#     => verify_nvidia_driver returns 1 and warns nothing; without libcuda => 0;
#   * neither ever dies, and neither changes the host.
#
# NOT covered: the probes' output is hand-written; whether lsmod/nvidia-smi
# really report this on a working node is only seen on one (run
# verify_nvidia there after gpu_setup).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile mutating_lines working_driver );
use Rex::GPU::NVIDIA;

my @LOADED = ( [ q{lsmod | grep '^nvidia '} => 'nvidia  104071168  0', 0 ] );

sub verify {
  my ( $fn, %over ) = @_;
  my $ret;
  my $rec = record_host(
    host => host_profile('debian-12', %over),
    code => sub { no strict 'refs'; $ret = &{"Rex::GPU::NVIDIA::$fn"}() }
  );
  return ( $ret, $rec );
}

sub warns { my ( $rec ) = @_; map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $rec->{logs} } }

subtest 'verify_nvidia: all ok => 1, no warning' => sub {
  my ( $ret, $rec ) = verify('verify_nvidia',
    responses => [ @LOADED, working_driver() ], can_run => { 'nvidia-ctk' => 1 });
  is($rec->{error}, undef, 'no die');
  is($ret, 1, 'returns 1');
  is_deeply([ warns($rec) ], [], 'no warning');
  is_deeply($rec->{lines}, [
    q{run: lsmod | grep '^nvidia '},
    'run: nvidia-smi -L 2>&1',
    'can_run: nvidia-ctk'
  ], 'module, nvidia-smi, nvidia-ctk -- no libcuda probe');
};

subtest 'verify_nvidia: no nvidia-ctk => 0' => sub {
  my ( $ret, $rec ) = verify('verify_nvidia', responses => [ @LOADED, working_driver() ]);
  is($rec->{error}, undef, 'no die');
  is($ret, 0, 'returns 0');
  my @w = warns($rec);
  is(scalar(@w), 2, 'two warnings');
  like($w[0], qr/nvidia-container-toolkit not found/, '... the toolkit');
  like($w[1], qr/GPU verification incomplete/, '... the summary');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'changes nothing');
};

subtest 'verify_nvidia_driver: all ok => 1, no warning' => sub {
  my ( $ret, $rec ) = verify('verify_nvidia_driver', responses => [ @LOADED, working_driver() ]);
  is($rec->{error}, undef, 'no die');
  is($ret, 1, 'returns 1');
  is_deeply([ warns($rec) ], [], 'no warning');
  ok(!(grep { /can_run/ } @{ $rec->{lines} }), 'does not look for nvidia-ctk');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'changes nothing');
};

subtest 'verify_nvidia_driver: libcuda missing => 0' => sub {
  my ( $ret, $rec ) = verify('verify_nvidia_driver', responses => [
    @LOADED, [ 'nvidia-smi -L 2>&1' => 'GPU 0: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-0)', 0 ]
  ]);
  is($ret, 0, 'returns 0');
  my @w = warns($rec);
  like($w[0], qr/libcuda\.so\.1 not in the linker cache/, 'warns about libcuda');
  like($w[-1], qr/NVIDIA driver verification incomplete/, '... and the summary');
};

done_testing;
