#!/usr/bin/env perl
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
# GH200 (2342, 2348) are narrow rows ahead of the Turing-to-Hopper block they
# sit inside (karr #72, maintainer decision -- NVIDIA's own driver README
# still lists Hopper as proprietary-supported, with no Grace exception):
# open kernel module, min_branch 535 (2342) / 565 (2348), compute 1. The
# neighbours 2341/2343/2347/2349 stay on the Hopper block's row, so the
# boundary of each narrow row is pinned on both sides.
#
# k107 REPLACES the karr #54 claim "1DF7..28FF is one row without
# bounds" (2330 H100, 2684 RTX 4090 and 28f8 => no min_branch), deliberately:
# Debian 11's 470 passed it for Ada and Hopper, which no 470 README lists.
# Now Turing/Ampere 1DF7..22FF and 2400..25FF stay unbound, Hopper
# 2300..23FF and Ada 2600..28FF need 520, and 88 IDs that NVIDIA's
# supportedchips READMEs list first in a later branch have single-ID rows
# with that branch (%FIRST_LISTED below, copied from the research, not from
# the code). Their neighbours fall back to the block, which pins every row to
# one ID. The Debian non-free branches (470/535/550) against those rows are in
# the satisfied_by matrix.
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
my $TA      = [ 'Turing/Ampere', 'either', undef, undef ];
my $HOP     = [ 'Hopper', 'either', 520, undef ];
my $ADA     = [ 'Ada', 'either', 520, undef ];
my $KEP     = [ 'Kepler or older', 'proprietary', undef, 470 ];
my $GH200A  = [ 'Grace Hopper', 'open', 535, undef ];   # 2342, 120GB/480GB
my $GH200B  = [ 'Grace Hopper', 'open', 565, undef ];   # 2348, 144G HBM3e

# k107: the IDs NVIDIA lists first in a branch newer than their block's
# floor (Turing/Ampere: 470, Hopper and Ada: 520), by that branch.
my %FIRST_LISTED = (
  'Hopper' => {
    525 => [qw( 2322 2324 2330 2339 )],
    535 => [qw( 2321 2329 232c 233a )],
    550 => [qw( 2335 )],
    565 => [qw( 233b )],
    580 => [qw( 230e )],
  },
  'Ada' => {
    525 => [qw( 26b1 26b5 2704 2717 2730 2757 2770 2782 2786 27a0 27b0 27b8 27ba 27bb
                27e0 2803 2805 2820 2838 2860 2882 28a0 28a1 28b8 28e0 28e1 28f8 )],
    535 => [qw( 26b2 26b3 26b9 26ba 27b1 27b2 27b6 27fb 28b9 28ba 28bb )],
    550 => [qw( 2685 2702 2705 2709 2783 2788 2808 2822 28a3 28b0 28e3 )],
    555 => [qw( 2689 )],
  },
  'Turing/Ampere' => {
    510 => [qw( 1f83 20f3 20f5 20f6 2207 2233 2238 24b1 24c9 2521 2544 25aa )],
    515 => [qw( 2582 25ab 25ac 25ad 25ec 25ed 25fb )],
    525 => [qw( 24c7 25bc 25bd )],
    535 => [qw( 20bd 20fd 2584 )],
    550 => [qw( 25b0 25b2 )],
  },
);

subtest 'generation table at the range boundaries' => sub {
  my %want = (
    '0000' => $KEP, '0020' => $KEP, '102d' => $KEP, '133f' => $KEP,
    '1340' => $MPV, '1db4' => $MPV, '1DB4' => $MPV, '1df6' => $MPV,
    # k107: Turing/Ampere | Hopper | Turing/Ampere | Ada, each edge on
    # both sides; 2238/230e/2348/2414/25fb/2684/28f8 are the listed IDs
    # nearest to an edge.
    '1df7' => $TA, '1e02' => $TA, '1f97' => $TA, '2204' => $TA, '22ff' => $TA,
    '2300' => $HOP, '2331' => $HOP, '2336' => $HOP, '23ff' => $HOP,
    '2400' => $TA, '2414' => $TA, '25fa' => $TA, '25ff' => $TA,
    '2600' => $ADA, '2684' => $ADA, '28ff' => $ADA,
    '2238' => [ 'Turing/Ampere', 'either', 510, undef ],
    '230e' => [ 'Hopper', 'either', 580, undef ],
    '25fb' => [ 'Turing/Ampere', 'either', 515, undef ],
    '28f8' => [ 'Ada', 'either', 525, undef ],
    # GH200 (karr #72): narrow rows ahead of the Hopper block they sit
    # inside; the neighbours just outside them stay $HOP.
    '2341' => $HOP, '2342' => $GH200A, '2343' => $HOP,
    '2347' => $HOP, '2348' => $GH200B, '2349' => $HOP,
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

subtest 'IDs listed first after their block floor: one row each (k107)' => sub {
  my %block = ( 'Hopper' => $HOP, 'Ada' => $ADA, 'Turing/Ampere' => $TA );
  my %own;
  for my $generation ( keys %FIRST_LISTED ) {
    for my $branch ( keys %{ $FIRST_LISTED{$generation} } ) {
      $own{$_} = [ $generation, 'either', $branch, undef ] for @{ $FIRST_LISTED{$generation}{$branch} };
    }
  }
  is( scalar keys %own, 88, '88 IDs with a row of their own' );
  for my $id ( sort keys %own ) {
    my $req = $R->for_device_id($id);
    is_deeply( shape($req), $own{$id}, $id.' => '.$own{$id}[0].', '.$own{$id}[2].' or newer' );
    is( $req->compute, 1, '... compute 1' );
    # A neighbour without a row of its own falls back to the block: the row
    # covers this one ID, not a range.
    for my $next ( map { sprintf '%04x', hex($id) + $_ } -1, 1 ) {
      next if $own{$next};
      is_deeply( shape( $R->for_device_id($next) ), $block{ $own{$id}[0] },
        '... neighbour '.$next.' => the '.$own{$id}[0].' block' );
    }
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
  my $prop535 = { kernel_module => 'proprietary', branch => 535 };
  my $prop550 = { kernel_module => 'proprietary', branch => 550 };
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
    [ $R->for_device_id('27b0'), $open565,       1 ],
    # k107: Debian's non-free branches (11: 470, 12: 535, 13: 550)
    [ $R->for_device_id('2204'), $prop470,       1 ],   # RTX 3090, in 470.256.02
    [ $R->for_device_id('1f83'), $prop470,       0 ],   # GTX 1630, first in 510
    [ $R->for_device_id('2331'), $prop470,       0 ],   # H100 PCIe, Hopper block 520
    [ $R->for_device_id('2684'), $prop470,       0 ],   # RTX 4090, Ada block 520
    [ $R->for_device_id('27b0'), $prop470,       0 ],   # RTX 4000 SFF Ada, 525
    [ $R->for_device_id('2600'), $prop470,       0 ],   # unlisted, Ada block
    [ $R->for_device_id('26b9'), $prop535,       1 ],   # L40S, 535
    [ $R->for_device_id('2335'), $prop535,       0 ],   # H200, 550
    [ $R->for_device_id('2783'), $prop535,       0 ],   # RTX 4070 SUPER, 550
    [ $R->for_device_id('2783'), $prop550,       1 ],
    [ $R->for_device_id('2689'), $prop550,       0 ],   # RTX 4070 Ti SUPER, 555
    [ $R->for_device_id('233b'), $prop550,       0 ],   # H200 NVL, 565
    [ $R->for_device_id('230e'), $prop550,       0 ],   # H20 NVL16, 580
    [ $R->for_device_id('230e'), $prop,          1 ]    # ... SUSE G06 / pinned 580
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
  like( $R->for_device_id('2684')->why_not({ kernel_module => 'proprietary', branch => 470 }),
    qr/^branch 470 is older than 520$/, 'why_not: Debian 11 non-free for an RTX 4090 (k107)' );
  is( $R->for_device_id('230e')->why_not({ kernel_module => 'open', branch_at_least => 580 }), undef,
    'H20 NVL16 (580) fits a "newest, at least 580" source (Ubuntu, RHEL)' );
};

subtest 'intersect' => sub {
  my $v100 = $R->from_gpu({ name => 'Tesla V100', device_id => '1db4' });
  my $p100 = $R->from_gpu({ name => 'Tesla P100', device_id => '15f8' });
  my $k80  = $R->from_gpu({ name => 'Tesla K80',  device_id => '102d' });
  my $b200 = $R->from_gpu({ name => 'B200',       device_id => '2901' });
  my $b300 = $R->from_gpu({ name => 'B300',       device_id => '3182' });
  my $h100 = $R->from_gpu({ name => 'H100',       device_id => '2330' });
  my $a100 = $R->from_gpu({ name => 'A100',       device_id => '20b0' });

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

  is_deeply( [ @{ shape( $R->intersect( $a100, $a100 ) ) }[ 1 .. 3 ] ],
    [ 'either', undef, undef ], 'either + either => either, no bounds' );
  is_deeply( [ @{ shape( $R->intersect( $a100, $h100 ) ) }[ 1 .. 3 ] ],
    [ 'either', 525, undef ], 'A100 + H100 => the H100 floor 525 (k107)' );

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
    'B200 (Blackwell, 10de:2901), H100 (Hopper, 10de:2330)',
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
  is_deeply( shape( $R->for_device_id('2330') ), [ 'Hopper', 'either', 525, undef ],
    'base class unaffected' );
  isa_ok( My::Test::Requirement->intersect( $h100, $h100 ), 'My::Test::Requirement' );
};

subtest 'compute by generation: Maxwell and later 1, Kepler or older 0' => sub {
  # karr #54 REPLACES the karr #45 claim "the Blackwell rows make a GPU
  # compute, no other row does" (maintainer decision: every GPU usable for AI
  # counts, MX/GT/GTX 9xx included, as long as a current driver branch
  # supports it -- the generation decides, not the name). The flag is now
  # three-valued: 1 (Maxwell .. Blackwell Ultra), 0 (Kepler or older, skipped
  # with a warning), undef (no row: the name rules and the unknown default).
  for my $id (qw( 1340 1380 13c0 174d 1d01 1db4 1df6 1df7 1e02 1f97 22ff 2300 2330 2342
                  2348 23ff 2400 25ff 2600 2684 2783 28ff
                  2900 2901 2c18 2c77 2bb9 2e12 2fff 3182 31c2 31c3 )) {
    is( $R->for_device_id($id)->compute, 1, $id.' => table compute 1' );
    is( Rex::GPU::Detect->_is_nvidia_compute( '0300', 'Device', $id ), 1,
      $id.' as VGA "Device" => compute' );
  }
  for my $id (qw( 0000 0fc5 1004 102d 128b 133f )) {
    is( $R->for_device_id($id)->compute, 0, $id.' => table compute 0 (Kepler or older)' );
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    is( Rex::GPU::Detect->_is_nvidia_compute( '0300', 'Device', $id ), 0,
      $id.' as VGA "Device" => not compute' );
  }
  for my $id ( qw( 3000 3181 3183 31c1 31c4 ffff ), undef ) {
    my $label = $id // 'undef';
    is( $R->for_device_id($id)->compute, undef, $label.' => no row, no verdict (undef)' );
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    is( Rex::GPU::Detect->_is_nvidia_compute( '0300', 'Device', $id ), 0,
      $label.' as VGA "Device" => not compute (unknown default)' );
  }
  my $b200 = $R->for_device_id('2901');
  is( $R->intersect( $b200, $b200 )->compute, undef,
    'an intersected requirement carries no compute flag' );
  # A subclass row changes the driver choice only: Detect reads the base table.
  is( My::Test::Requirement->for_device_id('2330')->compute, undef,
    'subclass row without compute => no verdict' );
  is( Rex::GPU::Detect->_is_nvidia_compute( '0300', 'Device', '2330' ), 1,
    '... Detect still reads the base table (2330 compute)' );
};

done_testing;
