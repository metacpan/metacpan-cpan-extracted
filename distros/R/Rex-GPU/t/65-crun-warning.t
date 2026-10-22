use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# karr #79: verify_nvidia warns about a crun older than 1.15 (1.14.1 is
# known broken: the GPU Operator's toolkit makes the crun runtime first and
# the OCI spec is rejected, "unknown version specified").
#
# CLAIMS:
#   * no crun on the host => silent, no `crun --version` run (the success
#     path is t/62's, unchanged apart from one can_run line);
#   * 1.14.1 and 1.9 warn naming version, consequence and remedy; 1.15,
#     1.15.0, 1.17 and 2.0 do not -- compared per numeric component, not as
#     strings;
#   * the warning never changes verify_nvidia's return value, and nothing
#     on the host is changed.
#
# NOT covered: what a real `crun --version` prints on a node (the canned
# first line is the upstream format, "crun version X").
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile working_driver );
use Rex::GPU::NVIDIA;

my @LOADED = ( [ q{lsmod | grep '^nvidia '} => 'nvidia  104071168  0', 0 ] );

sub verify_with_crun {
  my ( $version ) = @_;
  my $ret;
  my $rec = record_host(
    host => host_profile('debian-12',
      responses => [
        @LOADED, working_driver(),
        ( defined $version
          ? [ 'crun --version 2>&1' => "crun version $version\ncommit: abc\nspec: 1.0.0", 0 ] : () ),
      ],
      can_run => { 'nvidia-ctk' => 1, ( defined $version ? ( crun => 1 ) : () ) }),
    code => sub { $ret = Rex::GPU::NVIDIA::verify_nvidia() }
  );
  return ( $ret, $rec );
}

sub warns { my ( $rec ) = @_; map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $rec->{logs} } }

subtest 'no crun: silent' => sub {
  my ( $ret, $rec ) = verify_with_crun(undef);
  is($ret, 1, 'returns 1');
  is_deeply([ warns($rec) ], [], 'no warning');
  ok(!(grep { /crun --version/ } @{ $rec->{lines} }), 'crun --version not run');
};

for my $v (qw( 1.14.1 1.9 )) {
  subtest "crun $v: warns" => sub {
    my ( $ret, $rec ) = verify_with_crun($v);
    is($ret, 1, 'verify_nvidia still returns 1');
    my @w = warns($rec);
    is(scalar(@w), 1, 'one warning');
    like($w[0], qr/crun \Q$v\E found: older than 1\.15 \(known broken: 1\.14\.1\)/, 'version and bound');
    like($w[0], qr/unknown version specified/, 'consequence');
    like($w[0], qr/Update or remove crun, or keep runc as the first runtime/, 'remedy');
    is_deeply([ grep { !/^(?:can_run: |run: (?:lsmod |nvidia-smi |crun --version))/ } @{ $rec->{lines} } ],
      [], 'only read-only probes, nothing changed');
    golden_is($rec, 'verify/crun-'.$v);
  };
}

for my $v (qw( 1.15 1.15.0 1.17 2.0 )) {
  subtest "crun $v: silent" => sub {
    my ( $ret, $rec ) = verify_with_crun($v);
    is($ret, 1, 'returns 1');
    is_deeply([ warns($rec) ], [], 'no warning');
  };
}

done_testing;
