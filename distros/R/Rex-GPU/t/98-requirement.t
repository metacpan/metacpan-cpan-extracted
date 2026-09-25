use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for Rex::GPU::NVIDIA::Requirement (karr #30, epic karr #25).
#
# Pure value object, no run/dpkg/rpm. Claims pinned here:
#   * the generation table at every range boundary (and the IDs just outside)
#   * satisfied_by: kernel module x branch bounds, unknowns never pass a bound;
#     a "newest, at least N" source (branch_at_least) passes a min bound up to
#     N and never a max bound (karr #33); why_not says why
#   * intersect: either/min/max combine, conflicts croak naming both sides;
#     conflicts() returns the same reasons without dying
#   * a subclass overriding `generations` adds a row without touching the base
#   * the compute flag by generation (karr #45, #54): Maxwell .. Blackwell
#     Ultra rows 1, the Kepler-or-older row 0, no row undef
#
# GB10 (2e12) is its own row with min_branch 580, not the Blackwell block's
# 570 (karr #33): NVIDIA's open-gpu-kernel-modules README and the aarch64
# supportedchips README first list 2E12 in driver 580.119.02. The T1 claim
# "GB10 => Blackwell, 570" is REPLACED by that, deliberately.
#
# NOT covered: which driver a real host gets. The Setup classes pick their
# sources with this object (t/99, t/96), but none of it runs a package
# manager or a GPU.
# -----------------------------------------------------------------------------

use Rex::GPU::Detect;
use Rex::GPU::NVIDIA::Requirement;

my $R = 'Rex::GPU::NVIDIA::Requirement';

sub shape {
  my ( $req ) = @_;
  return [ map { $req->$_ } qw( generation kernel_module min_branch max_branch ) ];
}

my $UNKNOWN = [ undef, 'either', undef, undef ];
my $BW      = [ 'Blackwell', 'open', 570, undef ];
my $BWU     = [ 'Blackwell Ultra', 'open', 580, undef ];
my $GB10    = [ 'Blackwell', 'open', 580, undef ];
my $MPV     = [ 'Maxwell/Pascal/Volta', 'proprietary', undef, 580 ];
my $TAH     = [ 'Turing/Ampere/Ada/Hopper', 'either', undef, undef ];
my $KEP     = [ 'Kepler or older', 'proprietary', undef, 470 ];

subtest 'generation table at the range boundaries' => sub {
  my %want = (
    '0000' => $KEP, '0020' => $KEP, '102d' => $KEP, '133f' => $KEP,
    '1340' => $MPV, '1db4' => $MPV, '1DB4' => $MPV, '1df6' => $MPV,
    '1df7' => $TAH, '1e02' => $TAH, '1f97' => $TAH, '2330' => $TAH, '28f8' => $TAH,
    '28ff' => $TAH,
    '2900' => $BW, '2901' => $BW, '2e11' => $BW, '2e13' => $BW, '2fff' => $BW,
    '2e12' => $GB10, '2E12' => $GB10,
    '3000' => $UNKNOWN, '3181' => $UNKNOWN,
    '3182' => $BWU,
    '3183' => $UNKNOWN, '31c1' => $UNKNOWN,
    '31c2' => $BWU, '31c3' => $BWU,
    '31c4' => $UNKNOWN, 'ffff' => $UNKNOWN
  );
  for my $id ( sort keys %want ) {
    my $req = $R->for_device_id($id);
    is_deeply( shape($req), $want{$id}, $id.' => '.( $want{$id}[0] // 'unknown' ) );
    is( $req->device_id, lc $id, $id.' => device_id normalised to lowercase' );
  }
  for my $bad ( undef, '', '1db', 'zzzz', '1db40', '2b85x' ) {
    my $req = $R->for_device_id($bad);
    is_deeply( shape($req), $UNKNOWN, 'malformed '.( $bad // 'undef' ).' => unknown' );
    is( $req->device_id, undef, '... with no device_id' );
  }
};

subtest 'from_gpu' => sub {
  my $req = $R->from_gpu({ name => 'GV100GL [Tesla V100 PCIe 32GB]', device_id => '1db6' });
  is_deeply( shape($req), $MPV, 'V100 hashref => Maxwell/Pascal/Volta' );
  is( $req->name, 'GV100GL [Tesla V100 PCIe 32GB]', 'name carried for messages' );
  is_deeply( shape( $R->from_gpu({}) ), $UNKNOWN, 'no device_id => unknown' );
  ok( !eval { $R->from_gpu(undef); 1 }, 'undef dies' );
  like( $@, qr/needs a GPU hashref/, '... saying what it needs' );
  ok( !eval { $R->from_gpu('1db4'); 1 }, 'a bare ID string dies' );
};

subtest 'constructor validation' => sub {
  ok( !eval { $R->new( kernel_module => 'nouveau' ); 1 }, 'unknown kernel_module dies' );
  ok( !eval { $R->new( kernel_module => undef ); 1 },     'undef kernel_module dies' );
  ok( !eval { $R->new( min_branch => '580.95' ); 1 },     'non-integer branch dies' );
  ok( !eval { $R->new( device_id => '2E12' ); 1 },        'uppercase device_id via new dies' );
  ok( !eval { $R->new( min_branch => 590, max_branch => 580 ); 1 }, 'min above max dies' );
  like( $@, qr/min_branch 590 is above max_branch 580/, '... naming both' );
  is_deeply( shape( $R->new ), $UNKNOWN, 'defaults: either, no bounds' );
};

subtest 'satisfied_by' => sub {
  my $open    = { kernel_module => 'open',        branch => 580 };
  my $prop    = { kernel_module => 'proprietary', branch => 580 };
  my $open570 = { kernel_module => 'open',        branch => 570 };
  my $open565 = { kernel_module => 'open',        branch => 565 };
  my $prop595 = { kernel_module => 'proprietary', branch => 595 };
  my $prop470 = { kernel_module => 'proprietary', branch => 470 };
  my $open_nobranch = { kernel_module => 'open' };
  my $nomodule      = { branch => 580 };

  my @matrix = (
    # requirement,              source,          want
    [ $R->new,                  $open,           1 ],
    [ $R->new,                  $prop,           1 ],
    [ $R->new,                  $open_nobranch,  1 ],
    [ $R->new,                  $nomodule,       1 ],
    [ $R->for_device_id('2901'), $open,          1 ],
    [ $R->for_device_id('2901'), $open570,       1 ],
    [ $R->for_device_id('2901'), $open565,       0 ],
    [ $R->for_device_id('2901'), $prop,          0 ],
    [ $R->for_device_id('2901'), $open_nobranch, 0 ],
    [ $R->for_device_id('2901'), $nomodule,      0 ],
    [ $R->for_device_id('3182'), $open570,       0 ],
    [ $R->for_device_id('3182'), $open,          1 ],
    [ $R->for_device_id('1db4'), $prop,          1 ],
    [ $R->for_device_id('1db4'), $prop470,       1 ],
    [ $R->for_device_id('1db4'), $prop595,       0 ],
    [ $R->for_device_id('1db4'), $open,          0 ],
    [ $R->for_device_id('102d'), $prop470,       1 ],
    [ $R->for_device_id('102d'), $prop,          0 ],
    [ $R->for_device_id('27b0'), $prop595,       1 ],
    [ $R->for_device_id('27b0'), $open565,       1 ]
  );
  for my $row (@matrix) {
    my ( $req, $src, $want ) = @$row;
    is( $req->satisfied_by($src), $want,
      ( $req->device_id // 'unbound' ).' ('.$req->describe.') vs '
      .( $src->{kernel_module} // '?' ).'/'.( $src->{branch} // '?' ).' => '.$want );
  }
  ok( !eval { $R->new->satisfied_by(undef); 1 }, 'undef source dies' );
  ok( !eval { $R->new->satisfied_by({ kernel_module => 'open', branch_at_least => 'new' }); 1 },
    'non-integer branch_at_least dies' );
  ok( !eval { $R->new->satisfied_by({ kernel_module => 'open', branch => '580.95.05' }); 1 },
    'full version string as branch dies' );
};

subtest 'satisfied_by: "newest branch, at least N" (branch_at_least)' => sub {
  my $open590 = { kernel_module => 'open',        branch_at_least => 590 };
  my $prop580 = { kernel_module => 'proprietary', branch_at_least => 580 };
  my $prop560 = { kernel_module => 'proprietary', branch_at_least => 560 };
  my $unknown = { kernel_module => 'proprietary' };
  my @matrix = (
    [ $R->new,                   $prop580, 1, 'no bounds: any floor fits' ],
    [ $R->for_device_id('2901'), $open590, 1, 'Blackwell min 570 <= floor 590' ],
    [ $R->for_device_id('3182'), $open590, 1, 'Blackwell Ultra min 580 <= floor 590' ],
    [ $R->for_device_id('2901'), $prop580, 0, 'Blackwell: module first' ],
    [ $R->new( min_branch => 600 ), $prop580, 0, 'min 600 above the floor 580' ],
    [ $R->new( min_branch => 580 ), $prop560, 0, 'min 580 above the floor 560' ],
    [ $R->for_device_id('1db4'), $prop580, 0, 'max 580: newest can pass it, never fits' ],
    [ $R->for_device_id('1db4'), $prop560, 0, '... whatever the floor' ],
    [ $R->for_device_id('1db4'), $unknown, 0, 'unknown branch never fits a bound' ],
    [ $R->new,                   $unknown, 1, '... but fits no bound' ],
    [ $R->for_device_id('1db4'), { %$prop560, branch => 580 }, 1,
      'an exact branch wins over branch_at_least' ]
  );
  for my $row (@matrix) {
    my ( $req, $src, $want, $label ) = @$row;
    is( $req->satisfied_by($src), $want, $label.' => '.$want );
    is( defined $req->why_not($src) ? 0 : 1, $want, '... why_not agrees' );
  }
  like( $R->for_device_id('1db4')->why_not($prop580), qr/newest branch .* newer than 580/,
    'why_not: the max-bound reason' );
  like( $R->new( min_branch => 600 )->why_not($prop580), qr/known only to be 580 or newer; 600 is needed$/,
    'why_not: the floor reason' );
  like( $R->for_device_id('2901')->why_not($prop580),
    qr/^proprietary kernel module, the open one is needed$/, 'why_not: the module reason' );
  like( $R->for_device_id('1db4')->why_not({ kernel_module => 'proprietary', branch => 590 }),
    qr/^branch 590 is newer than 580$/, 'why_not: exact branch too new' );
  like( $R->for_device_id('2901')->why_not({ kernel_module => 'open', branch => 565 }),
    qr/^branch 565 is older than 570$/, 'why_not: exact branch too old' );
};

subtest 'intersect' => sub {
  my $v100 = $R->from_gpu({ name => 'Tesla V100', device_id => '1db4' });
  my $p100 = $R->from_gpu({ name => 'Tesla P100', device_id => '15f8' });
  my $k80  = $R->from_gpu({ name => 'Tesla K80',  device_id => '102d' });
  my $b200 = $R->from_gpu({ name => 'B200',       device_id => '2901' });
  my $b300 = $R->from_gpu({ name => 'B300',       device_id => '3182' });
  my $h100 = $R->from_gpu({ name => 'H100',       device_id => '2330' });

  is( $R->intersect($v100), $v100, 'one requirement comes back unchanged' );

  my $bw = $R->intersect( $b200, $h100 );
  is_deeply( [ @{ shape($bw) }[ 1 .. 3 ] ], [ 'open', 570, undef ], 'either + open => open' );
  is( $bw->generation, undef, 'combined has no generation' );
  is_deeply( $bw->members, [ $b200, $h100 ], 'members lists the inputs' );

  my $bwu = $R->intersect( $b200, $b300 );
  is( $bwu->min_branch, 580, 'min_branch is the highest lower bound' );

  my $old = $R->intersect( $v100, $k80 );
  is_deeply( [ @{ shape($old) }[ 1 .. 3 ] ], [ 'proprietary', undef, 470 ],
    'max_branch is the lowest upper bound' );

  is_deeply( [ @{ shape( $R->intersect( $h100, $h100 ) ) }[ 1 .. 3 ] ],
    [ 'either', undef, undef ], 'either + either => either, no bounds' );

  my $nested = $R->intersect( $R->intersect( $v100, $p100 ), $h100 );
  is_deeply( $nested->members, [ $v100, $p100, $h100 ], 'nested intersections flatten' );
  is( $nested->max_branch, 580, '... and keep their bounds' );

  my $inst = $b200->intersect($b300);
  is_deeply( $inst->members, [ $b200, $b300 ], 'object invocant is one of the requirements' );

  ok( !eval { $R->intersect( $v100, $b200 ); 1 }, 'V100 + B200 dies' );
  like( $@, qr/no single NVIDIA driver supports all GPUs/, '... says why' );
  like( $@, qr/B200 \(Blackwell, 10de:2901\) needs the open kernel module/, '... names the open side' );
  like( $@, qr/Tesla V100 \(Maxwell\/Pascal\/Volta, 10de:1db4\) needs the proprietary one/,
    '... names the proprietary side' );

  ok( !eval { $v100->intersect($b200); 1 }, 'same conflict via object invocant' );

  my $new_only = $R->new( name => 'Future GPU', min_branch => 590 );
  ok( !eval { $R->intersect( $new_only, $h100, $v100 ); 1 },
    'min 590 + max 580 dies (branch conflict, no module conflict)' );
  like( $@, qr/Future GPU needs driver branch 590 or newer, but Tesla V100 .* up to branch 580/,
    '... naming both bounds' );

  ok( !eval { $R->intersect( $new_only, $b200, $v100 ); 1 }, 'both conflicts at once' );
  like( $@, qr/open kernel module.*; .*branch 590 or newer/, '... reports both' );

  is_deeply( [ $R->conflicts( $v100, $p100, $h100 ) ], [], 'conflicts: none for V100 + P100 + H100' );
  my @why = $R->conflicts( $new_only, $b200, $v100 );
  is( scalar @why, 2, 'conflicts: both, without dying' );
  like( $why[0], qr/^B200 \(Blackwell, 10de:2901\) needs the open kernel module, but Tesla V100/,
    '... module conflict first, naming the GPUs' );
  is( $R->intersect( $b200, $h100 )->who,
    'B200 (Blackwell, 10de:2901), H100 (Turing/Ampere/Ada/Hopper, 10de:2330)',
    'who of an intersection lists its members' );

  ok( !eval { $R->intersect; 1 }, 'empty list dies' );
  ok( !eval { $R->intersect( $v100, { kernel_module => 'open' } ); 1 }, 'a hashref dies' );
};

subtest 'subclass overrides generations' => sub {
  {
    package My::Test::Requirement;
    use Moo;
    extends 'Rex::GPU::NVIDIA::Requirement';
    sub generations {
      my ( $self ) = @_;
      return (
        { generation => 'Hopper (site)', first => 0x2330, last => 0x2330,
          kernel_module => 'open', min_branch => 575 },
        $self->SUPER::generations
      );
    }
  }
  my $h100 = My::Test::Requirement->for_device_id('2330');
  isa_ok( $h100, 'My::Test::Requirement' );
  is_deeply( shape($h100), [ 'Hopper (site)', 'open', 575, undef ], 'added row wins' );
  is_deeply( shape( My::Test::Requirement->for_device_id('1db4') ), $MPV, 'built-in rows kept' );
  is_deeply( shape( $R->for_device_id('2330') ), $TAH, 'base class unaffected' );
  isa_ok( My::Test::Requirement->intersect( $h100, $h100 ), 'My::Test::Requirement' );
};

subtest 'compute by generation: Maxwell and later 1, Kepler or older 0' => sub {
  # karr #54 REPLACES the karr #45 claim "the Blackwell rows make a GPU
  # compute, no other row does" (maintainer decision: every GPU usable for AI
  # counts, MX/GT/GTX 9xx included, as long as a current driver branch
  # supports it -- the generation decides, not the name). The flag is now
  # three-valued: 1 (Maxwell .. Blackwell Ultra), 0 (Kepler or older, skipped
  # with a warning), undef (no row: the name rules and the unknown default).
  for my $id (qw( 1340 1380 13c0 174d 1d01 1db4 1df6 1df7 1e02 1f97 2330 28ff
                  2900 2901 2c18 2c77 2bb9 2e12 2fff 3182 31c2 31c3 )) {
    is( $R->for_device_id($id)->compute, 1, $id.' => table compute 1' );
    is( Rex::GPU::Detect::_is_nvidia_compute( '0300', 'Device', $id ), 1,
      $id.' as VGA "Device" => compute' );
  }
  for my $id (qw( 0000 0fc5 1004 102d 128b 133f )) {
    is( $R->for_device_id($id)->compute, 0, $id.' => table compute 0 (Kepler or older)' );
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    is( Rex::GPU::Detect::_is_nvidia_compute( '0300', 'Device', $id ), 0,
      $id.' as VGA "Device" => not compute' );
  }
  for my $id ( qw( 3000 3181 3183 31c1 31c4 ffff ), undef ) {
    my $label = $id // 'undef';
    is( $R->for_device_id($id)->compute, undef, $label.' => no row, no verdict (undef)' );
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    is( Rex::GPU::Detect::_is_nvidia_compute( '0300', 'Device', $id ), 0,
      $label.' as VGA "Device" => not compute (unknown default)' );
  }
  my $b200 = $R->for_device_id('2901');
  is( $R->intersect( $b200, $b200 )->compute, undef,
    'an intersected requirement carries no compute flag' );
  # A subclass row changes the driver choice only: Detect reads the base table.
  is( My::Test::Requirement->for_device_id('2330')->compute, undef,
    'subclass row without compute => no verdict' );
  is( Rex::GPU::Detect::_is_nvidia_compute( '0300', 'Device', '2330' ), 1,
    '... Detect still reads the base table (2330 compute)' );
};

done_testing;
