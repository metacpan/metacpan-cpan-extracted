#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# sleep() is a builtin: only a CORE::GLOBAL override installed before
# Rex::GPU::AMD is compiled reaches the sleeps of the reboot path (same trick
# as t/17-amd-dkms-held.t).
our @SLEPT;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @SLEPT, $_[0]; return $_[0] // 0 } }

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Rex::GPU::AMD::install_driver, dkms method on RHEL 9: a `dnf versionlock`
# that keeps the install from going through is named (karr k109).
#
# Since k95/k101 the apt layer names an `apt-mark hold` in the way; on RHEL
# package_held always said 0 and a version lock on amdgpu-dkms or kernel-devel
# went unnamed. Now the failure paths (post_install: no module built;
# verify_packages: a package missing after `dnf install -y`) read
# `dnf -q versionlock list 2>/dev/null` once and say what is locked.
#
# CLAIMS:
#   1. a dnf4 lock on amdgpu-dkms (`NAME-EPOCH:VERSION-RELEASE.*`), no module
#      built: the message names amdgpu-dkms as version-locked, says what dnf
#      does with a locked package, and gives `dnf versionlock delete
#      amdgpu-dkms ... and install_driver again`, then the make.log hint; the
#      same when amdgpu-dkms is missing after the install (verify_packages);
#   2. a lock on kernel-devel while the transaction failed (kernel-headers,
#      kernel-devel, kernel-devel-matched, amdgpu-dkms all missing): the die
#      for kernel-headers-<running kernel> reads `kernel-headers-K not
#      installed after dnf install -- check the dnf output; kernel-devel is
#      version-locked ...` -- kernel-devel only, not kernel-devel-matched;
#   3. versionlock exits 1 (plugin missing): the old messages, word for word,
#      the list asked exactly once per failed install, and no plugin (nor
#      anything else) installed for it -- one `dnf install` line, the plan's;
#      an exit 1 whose output still looks like a lock list is no lock either;
#   4. dnf5's format (`Package name: amdgpu-dkms`, then its conditions): named;
#   5. the running kernel's kernel-devel locked and installed: not named;
#   6. a lock on kernel-devel with kernel-devel-matched missing (kernel-devel
#      installed) does not count for kernel-devel-matched: the old message;
#   7. kernel-devel-matched missing and itself locked: named;
#   8. amdgpu-dkms-firmware locked and not installed: named (post_install and
#      verify_packages);
#   9. amdgpu-dkms-firmware locked and installed: not named;
#  10. the install went through (module built), a lock on amdgpu-dkms and the
#      firmware not installed on the host: lives, returns dkms, and runs
#      neither `dnf -q versionlock list` nor an `rpm -q` beyond the two per
#      plan package (before the install and verify_packages) -- no `rpm -q` of
#      the firmware: the success path gets no new host line;
#   and in all: no `pkg:` line, no unmocked Rex function, and the lock list
#   is a read-only line for the harness (no mutating line carries it).
#
# NOT covered:
#   * what dnf really does with a locked package (leave it, or fail the whole
#     transaction) and on which RHEL 8/9/10 minor -- the message states it,
#     nothing here runs dnf; whether `dnf versionlock delete` then lets the
#     install through; whether dnf4's versionlock also filters `dnf repoquery`
#     (then resolve_plan dies earlier, with "no candidate", before the lock is
#     read: the worker's open question on k109, not shown here);
#   * the lock-list lines are hand-written. dnf4's `NAME-EPOCH:VERSION-RELEASE.*`
#     (and the `!` of an exclude) follows the versionlock plugin's documented
#     format, the entry strings are invented; dnf5's `Package name:` block is
#     the worker's reading of dnf5 and was NOT checked against a dnf5 here;
#   * a lock on amdgpu-dkms is named whichever version it pins -- a lock at
#     the candidate is a false positive the code accepts (card k109);
#   * the `rpm -q` answers are the plain two forms (`PKG` / `package PKG is
#     not installed`, exit 1), hand-written; RHEL 8 (no kernel-devel-matched),
#     RHEL 10 and Rocky/Alma are not exercised here;
#   * a real DKMS build, a reboot, make.log.
# This fails against HEAD: package_held there is always 0, no lock is read.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host mutating_lines );
use Test::RexGPU::AMD qw( amd_host amd_state gpu_mi300x sequence os_kernel );
use Rex::GPU::AMD;

{
  package Local::FakeConn;
  sub new { bless { disconnects => 0, reconnects => 0 }, shift }
  sub disconnect { $_[0]{disconnects}++; return 1 }
  sub reconnect  { $_[0]{reconnects}++; return 1 }
}

my $SLOT = { slot => '0000:c1:00.0', class => '1200', device_id => '74a1' };
my $FRESH   = amd_state(amdgpu => 0, kfd => 0, gpus => [ { %$SLOT, driver => undef, render => undef } ]);
my $WORKING = amd_state(gpus => [ { %$SLOT, kfd => 90402, vram => 137438953472, gtt => 33535848448 } ]);

my $K        = os_kernel('rhel-9');          # 5.14.0-570.12.1.el9_6.x86_64
my $HEADERS  = "kernel-headers-$K";
my $DEVEL    = "kernel-devel-$K";
my $MATCHED  = "kernel-devel-matched-$K";
my @PLAN     = ( $HEADERS, $DEVEL, $MATCHED, 'amdgpu-dkms' );
my $FW       = 'amdgpu-dkms-firmware';
my $MAKE_LOG = '/var/lib/dkms/amdgpu/*/build/make.log';
my $LIST_CMD = 'dnf -q versionlock list 2>/dev/null';

# dnf4 versionlock entries: the lock of a package at ANOTHER kernel / version
# than the running one is what a lock set at some earlier time looks like
my $LOCK_DKMS    = "amdgpu-dkms-1:6.16.13-2255209.el9.*\n";
my $LOCK_DEVEL   = "kernel-devel-0:5.14.0-427.13.1.el9_4.*\n";
my $LOCK_MATCHED = "kernel-devel-matched-0:5.14.0-427.13.1.el9_4.*\n";
my $LOCK_FW      = "amdgpu-dkms-firmware-1:6.16.13-2255209.el9.*\n";

# install_driver(method => dkms) on RHEL 9, an MI300X, no module is ever built.
#   missing  => [ pkg, ... ]  plan packages (specs as rpm -q takes them) that
#                             are not installed after the install
#   firmware => 'installed' | 'missing'   rpm -q of amdgpu-dkms-firmware
#   lock     => [ out, exit ] the answer of `dnf -q versionlock list`
#   built    => 1            the module is built after the install (dkms status:
#                            nothing before, installed after; modinfo: dkms)
sub rhel_install {
  my ( %o ) = @_;
  my %missing = map { $_ => 1 } @{ $o{missing} // [] };
  my @r;
  for my $pkg (@PLAN) {
    my $nevra = $pkg eq 'amdgpu-dkms' ? 'amdgpu-dkms-1:6.16.13-2255209.el9.noarch' : $pkg =~ s/-\Q$K\E\z/-0:$K/r;
    my $after = $missing{$pkg} ? [ "package $pkg is not installed", 1 ] : [ $pkg, 0 ];
    push @r,
      # not installed before the install (has_candidate / plan), the final state after it
      [ qr{^rpm -q \Q$pkg\E 2>&1$} => sequence([ "package $pkg is not installed", 1 ], $after), 0 ],
      [ "dnf -q repoquery --available $pkg 2>&1" => $nevra, 0 ];
  }
  push @r, [ "rpm -q $FW 2>&1" => ( ( $o{firmware} // 'installed' ) eq 'installed'
    ? ( "$FW-1:6.16.13-2255209.el9.noarch", 0 ) : ( "package $FW is not installed", 1 ) ) ];
  push @r, [ $LIST_CMD => @{ $o{lock} } ] if $o{lock};
  my $dkms = $o{built} ? sequence([ '', 0 ], [ "amdgpu/6.16.13-2255209, $K, x86_64: installed", 0 ]) : '';
  my $host = amd_host('rhel-9', kernel => $K, state => [ $FRESH, $WORKING ], module => $o{built} ? 'dkms' : 'none',
    responses => [ @r, [ qr{^dkms status -m amdgpu -k } => $dkms, 0 ] ]);
  @SLEPT = ();
  return record_host(
    host => $host,
    subs => { 'Rex::get_current_connection' => sub { return { conn => Local::FakeConn->new } } },
    code => sub { Rex::GPU::AMD::install_driver(gpus => [ gpu_mi300x() ], method => 'dkms') },
  );
}

# The wording, spelled out here and not taken from the code.
sub lock_sentence {
  my ( @held ) = @_;
  my $names = @held > 1 ? join(', ', @held[0 .. $#held - 1]).' and '.$held[-1] : $held[0];
  return $names.( @held > 1 ? ' are' : ' is' ).' version-locked (dnf versionlock), and dnf install leaves a locked '
    .'package at its locked version (where the install needs another one, it fails). Run dnf versionlock delete '
    .join(' ', @held).' and install_driver again';
}
# post_install: the package is installed, no module built
sub built_message {
  my ( @held ) = @_;
  return "install_driver: amdgpu-dkms is installed, but dkms reports no amdgpu module built and installed for kernel $K; "
    .( @held ? lock_sentence(@held)."; if the module is still missing then, " : '' )."see $MAKE_LOG";
}
# verify_packages: the first missing package
sub missing_message {
  my ( $pkg, @held ) = @_;
  return "$pkg not installed after dnf install -- check the dnf output".( @held ? '; '.lock_sentence(@held) : '' );
}

sub no_pkg { my ( $rec ) = @_; return !grep { /^pkg:/ } @{ $rec->{lines} } }
sub count_lines { my ( $rec, $re ) = @_; return scalar grep { /$re/ } @{ $rec->{lines} } }
sub list_asked { my ( $rec ) = @_; return count_lines($rec, qr/\Arun: \Q$LIST_CMD\E\z/) }
sub sane {
  my ( $rec, $label ) = @_;
  ok(no_pkg($rec), "$label: no pkg: line");
  ok(!$rec->{trapped}, "$label: no unmocked Rex function reached");
}

subtest 'claim 1: a dnf4 lock on amdgpu-dkms is named, in post_install and in verify_packages' => sub {
  my $rec = rhel_install(lock => [ $LOCK_DKMS, 0 ]);
  is($rec->{error}, built_message('amdgpu-dkms'), 'module not built: named, with the way out, then make.log');
  is(list_asked($rec), 1, '... the lock list asked once');
  is(count_lines($rec, qr/versionlock/), 1, '... and nothing else of versionlock');
  is(count_lines($rec, qr/\Arun: \Q$LIST_CMD\E\z/), 1, '... as the exact command, stderr dropped');
  is_deeply([ grep { /versionlock/ } mutating_lines(@{ $rec->{lines} }) ], [], '... the harness counts it read-only');
  sane($rec, 'built');

  $rec = rhel_install(lock => [ $LOCK_DKMS, 0 ], missing => [ 'amdgpu-dkms' ]);
  is($rec->{error}, missing_message('amdgpu-dkms', 'amdgpu-dkms'), 'amdgpu-dkms missing: named');
  is(list_asked($rec), 1, '... the lock list asked once');
  sane($rec, 'missing');
};

subtest 'claim 2: a lock on kernel-devel, the transaction failed: kernel-devel only' => sub {
  my $rec = rhel_install(lock => [ $LOCK_DEVEL, 0 ], missing => [ @PLAN ]);
  is($rec->{error}, missing_message($HEADERS, 'kernel-devel'), 'dies for the first package, naming kernel-devel');
  unlike($rec->{error}, qr/kernel-devel-matched is|and kernel-devel-matched|kernel-devel-matched and/, '... not kernel-devel-matched');
  is(list_asked($rec), 1, '... the lock list asked once');
  sane($rec, 'devel');
};

subtest 'claim 3: versionlock fails (no plugin): the old messages, asked once, nothing installed for it' => sub {
  for my $case ([ 'empty, exit 1' => [ '', 1 ] ],
                [ 'a lock list that still prints, exit 1' => [ $LOCK_DKMS, 1 ] ]) {
    my ( $label, $answer ) = @$case;
    my $rec = rhel_install(lock => $answer, missing => [ 'amdgpu-dkms' ]);
    is($rec->{error}, missing_message('amdgpu-dkms'), "$label: verify_packages: the old message, word for word");
    is(list_asked($rec), 1, '... the lock list asked exactly once');
    is(count_lines($rec, qr/\Arun: dnf install /), 1, '... one dnf install: the plan\'s');
    is(count_lines($rec, qr/python3-dnf-plugin|dnf-command|install .*versionlock/), 0, '... no plugin installed');
    sane($rec, $label);

    $rec = rhel_install(lock => $answer);
    is($rec->{error}, built_message(), "$label: post_install: the old message, word for word");
    is(list_asked($rec), 1, '... the lock list asked exactly once');
  }
};

subtest 'claim 4: dnf5 prints "Package name:": named' => sub {
  my $list = "# Added by 'versionlock add' command on 2026-11-01 10:00:00\nPackage name: amdgpu-dkms\n    evr = 1:6.16.13-2255209.el9\n";
  my $rec = rhel_install(lock => [ $list, 0 ]);
  is($rec->{error}, built_message('amdgpu-dkms'), 'named, the conditions line is no entry');
  sane($rec, 'dnf5');
};

subtest 'claim 5: the running kernel\'s kernel-devel locked and installed: not named' => sub {
  my $rec = rhel_install(lock => [ "kernel-devel-0:$K\n" =~ s/\.x86_64\n/.*\n/r, 0 ]);
  is($rec->{error}, built_message(), 'the plain message');
  is(list_asked($rec), 1, '... the list was read (that is why nothing is named)');
};

subtest 'claim 6: a lock on kernel-devel does not count for kernel-devel-matched' => sub {
  my $rec = rhel_install(lock => [ $LOCK_DEVEL, 0 ], missing => [ $MATCHED ]);
  is($rec->{error}, missing_message($MATCHED), 'kernel-devel-matched missing, kernel-devel locked and installed: the old message');
  unlike($rec->{error}, qr/version-locked/, '... no lock named');
};

subtest 'claim 7: kernel-devel-matched missing and locked itself: named' => sub {
  my $rec = rhel_install(lock => [ $LOCK_MATCHED, 0 ], missing => [ $MATCHED ]);
  is($rec->{error}, missing_message($MATCHED, 'kernel-devel-matched'), 'named, as kernel-devel-matched');
  sane($rec, 'matched');
};

subtest 'claim 8: the firmware locked and not installed: named' => sub {
  my $rec = rhel_install(lock => [ $LOCK_FW, 0 ], firmware => 'missing');
  is($rec->{error}, built_message($FW), 'post_install names the firmware');
  $rec = rhel_install(lock => [ $LOCK_FW, 0 ], firmware => 'missing', missing => [ 'amdgpu-dkms' ]);
  is($rec->{error}, missing_message('amdgpu-dkms', $FW), 'verify_packages names it');
  sane($rec, 'firmware');
};

subtest 'claim 9: the firmware locked and installed: not named' => sub {
  my $rec = rhel_install(lock => [ $LOCK_FW, 0 ], firmware => 'installed');
  is($rec->{error}, built_message(), 'post_install: the plain message');
  $rec = rhel_install(lock => [ $LOCK_FW, 0 ], firmware => 'installed', missing => [ 'amdgpu-dkms' ]);
  is($rec->{error}, missing_message('amdgpu-dkms'), 'verify_packages: the plain message');
};

subtest 'claim 10: the install went through: no lock list, no new rpm -q' => sub {
  my $rec = rhel_install(built => 1, lock => [ $LOCK_DKMS, 0 ], firmware => 'missing');
  is($rec->{error}, undef, 'lives, a lock on amdgpu-dkms and a missing firmware notwithstanding');
  is(count_lines($rec, qr/versionlock/), 0, 'no dnf versionlock line at all');
  is(count_lines($rec, qr/\Q$FW\E/), 0, 'nothing asks about amdgpu-dkms-firmware');
  is_deeply([ sort grep { /\Arun: rpm -q / } @{ $rec->{lines} } ],
    [ sort map {; "run: rpm -q $_ 2>&1", "run: rpm -q $_ 2>&1" } @PLAN ],
    'rpm -q: exactly twice per plan package (before the install, in verify_packages)');
  is(count_lines($rec, qr/\Arun: dnf install /), 1, 'one dnf install');
  sane($rec, 'success');
};

done_testing;
