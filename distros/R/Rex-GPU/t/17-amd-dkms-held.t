#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# sleep() is a builtin: only a CORE::GLOBAL override installed before
# Rex::GPU::AMD is compiled reaches the sleeps of the reboot path (same trick
# as t/17-amd-install-driver.t).
our @SLEPT;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @SLEPT, $_[0]; return $_[0] // 0 } }

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Rex::GPU::AMD::install_driver, dkms method: the die for "amdgpu-dkms is
# installed, but dkms reports no amdgpu module built" names a hold on
# amdgpu-dkms (karr k95).
#
# `apt-get install -y` does not change a package that is on hold (apt-mark
# hold), and aborts the install where the change would have to be made. The
# package then shows `hi` for dpkg -l, passes verify_packages (k89), and no
# module is built for the running kernel: the old message sent the operator to
# make.log, which does not exist or is stale. Since k95 post_install asks dpkg
# for the selection of amdgpu-dkms, but only on that failure path.
#
# CLAIMS:
#   * apt (Ubuntu 24.04, Debian 13 and 12), method dkms, amdgpu-dkms on hold
#     (dpkg -l `hi`, ${Status} `hold ok installed`), no module in `dkms status`
#     afterwards: dies with the message that names the hold, says `apt-get
#     install -y` does not change a held package, gives `apt-mark unhold
#     amdgpu-dkms`, and still points at /var/lib/dkms/amdgpu/*/build/make.log;
#   * the same without a hold (`ii`, `install ok installed`): the message is
#     the old one, character for character (anchored, nothing appended);
#   * a hold with the Status of a package that is not installed (`hold ok
#     not-installed`) counts as held too (the selection is what is asked);
#   * held, but the module is built after the install: lives, returns dkms, and
#     no dpkg-query for amdgpu-dkms is run -- the question belongs on the
#     failure path only;
#   * RHEL 9, no module built: the old message, and no dpkg-query at all
#     (Setup::package_held answers 0 without a host command);
#   * none of the cases routes a package through Rex::Pkg (no `pkg:` line) and
#     no unmocked Rex function is reached.
#
# NOT covered:
#   * what `apt-get install -y` really does to a held package on a given
#     release (leave it, or abort) -- the message states it, nothing here runs
#     apt; whether `apt-mark unhold` then lets the build through;
#   * the ${Status} lines are hand-written in dpkg-query's documented format
#     ("amdgpu-dkms hold ok installed 1:6.16.13-2255209.24.04"), not captured
#     on a host; the version string is invented in its shape;
#   * the `dkms status` answers are hand-written (see Test::RexGPU::AMD); a
#     real failed build can leave other lines (`added`, `built`) than the
#     empty answer scripted here, all of which count as "not installed";
#   * a hold set some other way than apt-mark/dpkg --set-selections (an apt
#     preferences pin does not show in ${Status}), and a held amdgpu-dkms that
#     is not the cause of the missing module;
#   * the make.log itself, a real DKMS build, a reboot.
# This test fails against the code before k95 (the held cases get the old
# message) and passes after.
#
# k101: the same question one step earlier. verify_packages (apt) runs after
# `apt-get install -y` and before any module check; with amdgpu-dkms in the
# plan (dkms) and ANY package of it missing, it asks for the hold -- a held
# amdgpu-dkms that "would have to change" aborts the whole install, so the
# header package can be the one missing just as well.
#
# CLAIMS (k101):
#   * dkms, amdgpu-dkms `hold ok not-installed` and not installed afterwards
#     (headers installed): the die names amdgpu-dkms, the hold and `apt-mark
#     unhold amdgpu-dkms`, then the make.log hint ("; if it is still not
#     installed then, a failed DKMS build ...");
#   * dkms, the header package missing and amdgpu-dkms held (`hold ok
#     not-installed`, and `hold ok installed` at another version): the die
#     names the header package, the hold and apt-mark unhold, and NO make.log
#     hint;
#   * dkms, not held (`install ok ...`), amdgpu-dkms or the header package
#     missing: the old messages, character for character (anchored);
#   * an inbox plan (no amdgpu-dkms in it) with a held amdgpu-dkms on the host
#     and a package missing: the old message, and no dpkg-query for
#     amdgpu-dkms;
#   * everything installed, amdgpu-dkms held: no dpkg-query for amdgpu-dkms
#     (the success path gets no new host line);
#   * on the failure path the hold is asked exactly once;
#   * RHEL: no dpkg-query, no `pkg:` line, no unmocked Rex function reached.
# These fail against the code before k101 (the held cases get the old message).
# NOT covered (k101): whether apt really aborts for a held package on a given
# release; a hold by apt preferences pin; the header package name on kernels
# other than the scripted ones; the dpkg-query answers are hand-written.
#
# k108: which holds are named. The hold question is now ONE `dpkg-query -W`
# for every package of the plan plus amdgpu-dkms-firmware (no longer amdgpu-dkms
# alone), and a held package that IS installed is compared with its candidate
# by `LC_ALL=C apt-cache policy` (the answers of the k95/k101 cases below are
# re-keyed to that command and carry such a policy answer: UMGESTELLT, the
# claims stay). Ubuntu 24.04, method dkms, an MI300X, the failure path.
#
# CLAIMS (k108):
#   1. amdgpu-dkms held and installed BELOW the candidate, no module built:
#      the hold is named (post_install), and policy is asked once, for
#      amdgpu-dkms only;
#   2. held AT the candidate: only the make.log text, no hold -- and for
#      verify_packages' hF the build-log text only (this REPLACES k101's claim
#      "hF names the hold first", moved out of t/17-amd-install-driver.t); hF
#      below the candidate still names the hold first;
#   3. `hold ok not-installed`: named, and no policy question;
#   4. a header package missing and amdgpu-dkms held at the candidate: the old
#      message of the header package, no hold;
#   5. amdgpu-dkms-firmware held and not installed: named (post_install and
#      verify_packages), no policy question;
#   6. the header package held and not installed: named, no build-log hint;
#   7. the firmware held and installed: not named;
#   8. two holds: one sentence "X and Y are on hold", one `apt-mark unhold X Y`;
#   9. the policy answer empty, failed (exit 100), without Installed/Candidate
#      lines, or only for a foreign architecture: the hold is named, as before
#      k108;
#  10. an install that went through (module built, amdgpu-dkms held, firmware
#      held and missing): no dpkg-query and no apt-cache policy after the
#      install at all;
#  11. post_install and verify_packages carry the same hold sentence, for one
#      and for two holds, on Ubuntu 24.04, Debian 13 and 12.
# NOT covered (k108): that apt behaves as the message says for a held package
# of a dependency (a held, not installed amdgpu-dkms-firmware aborting
# `apt-get install -y amdgpu-dkms`); that amdgpu-dkms depends on
# amdgpu-dkms-firmware without a version on any release but the 31.60 ones the
# worker read (jammy, resolute, Debian: not read); the `apt-cache policy` and
# dpkg-query answers are hand-written in the documented formats, with invented
# version strings; Debian 12/13 stand in with the Ubuntu 24.04 plan shape
# (headers + amdgpu-dkms), the real plan may differ; an apt pin or a held
# package apt would pull in for another reason.
# This fails against HEAD: the hold question there is the single-package
# dpkg-query, the firmware and the candidate comparison do not exist.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host );
use Test::RexGPU::AMD qw( amd_host amd_state gpu_mi300x sequence os_kernel dpkg_l );
use Rex::GPU::AMD;

# A connection whose reconnect() works; install_driver does not reboot here.
{
  package Local::FakeConn;
  sub new { bless { disconnects => 0, reconnects => 0 }, shift }
  sub disconnect { $_[0]{disconnects}++; return 1 }
  sub reconnect  { $_[0]{reconnects}++; return 1 }
}

my $OLD = '1:6.16.13-2255209.24.04';   # a version below the candidate
my $NEW = '1:7.1.9.31600000-2407772.24.04';   # the candidate (shape of AMD's 31.60 package, invented)

my $SLOT = { slot => '0000:c1:00.0', class => '1200', device_id => '74a1' };
sub fresh {
  return amd_state(amdgpu => 0, kfd => 0, gpus => [ { %$SLOT, driver => undef, render => undef } ]);
}
sub working {
  return amd_state(gpus => [ { %$SLOT, kfd => 90402, vram => 137438953472, gtt => 33535848448 } ]);
}

# The hold question since k108: ONE dpkg-query -W for the plan's packages and
# amdgpu-dkms-firmware, in dpkg-query's format. $status/$version answer for
# amdgpu-dkms (undef $status: dpkg has no record of it, no line); @more are
# further answer lines "PKG STATUS VERSION" (a header package, the firmware).
# The answer also fits the single-package query of before k108 (amdgpu-dkms
# alone), so that a run against the old code fails on the claims, not on a
# command the host did not recognise; claim 1 pins the query itself.
sub dpkg_query {
  my ( $status, $version, @more ) = @_;
  return [ qr{^dpkg-query -W -f='\$\{Package\} \$\{Status\} \$\{Version\}\\n' (?:\S+ )*amdgpu-dkms(?:-firmware)? 2>/dev/null$}
    => join("\n", ( defined $status ? "amdgpu-dkms $status ".( $version // $OLD ) : () ), @more), 0 ];
}
sub held_queries { my ( $rec ) = @_; return scalar grep { /dpkg-query .*amdgpu-dkms/ } @{ $rec->{lines} } }

# apt-cache policy as apt prints it (LC_ALL=C), one package
sub policy_text {
  my ( $package, $installed, $candidate ) = @_;
  return "$package:\n  Installed: $installed\n  Candidate: $candidate\n  Version table:\n";
}
# The `apt-cache policy` lines after the install: the hold question's (k108),
# not resolve_plan's, which comes before apt-get install.
sub hold_policy_lines {
  my ( $rec ) = @_;
  my @lines = @{ $rec->{lines} };
  my ( $at ) = grep { $lines[$_] =~ /apt-get .* install -y / } 0 .. $#lines;
  return () unless defined $at;
  return grep { /apt-cache policy / } @lines[$at + 1 .. $#lines];
}

# install_driver(method => dkms) for an MI300X.
#   built => 1  the module is there after the install (dkms status: nothing
#               before, installed after); 0: nothing built, ever
#   dpkg  => 'hi' | 'ii' | 'un'   dpkg -l state of amdgpu-dkms (apt only)
#   status => '...'        the dpkg-query ${Status} answer (apt only; omitted: unanswered)
#   version => '...'       the ${Version} of that answer
#   headers => 'ii' | 'un' dpkg -l state of linux-headers-<kernel> (apt only; default ii)
#   more => [ 'PKG STATUS VERSION', ... ]  further dpkg-query answer lines (k108)
#   policy => [ out, exit ] the answer of `apt-cache policy amdgpu-dkms` to the
#               HOLD question (the one after the install; resolve_plan's before
#               it is always answered with a candidate). Omitted: the profile's
#               default answer, which has no block for amdgpu-dkms.
sub dkms_install {
  my ( $os, %o ) = @_;
  my $kernel = os_kernel($os);
  my $dkms = $o{built}
    ? sequence([ '', 0 ], [ "amdgpu/6.16.13-2255209.24.04, $kernel, x86_64: installed", 0 ])
    : sequence([ '', 0 ]);
  my $apt = $os !~ /^(?:rhel|rocky)/;
  my $host = amd_host($os,
    kernel => $kernel, state => [ fresh(), working() ], module => $o{built} ? 'dkms' : 'none',
    responses => [
      [ qr{^dkms status -m amdgpu -k } => $dkms, 0 ],
      ( $apt ? ( dpkg_l('amdgpu-dkms' => $o{dpkg} // 'ii', "linux-headers-$kernel" => $o{headers} // 'ii'),
                 ( defined $o{status} || $o{more} ? dpkg_query($o{status}, $o{version}, @{ $o{more} // [] }) : () ),
                 ( $o{policy} ? [ 'LC_ALL=C apt-cache policy amdgpu-dkms 2>/dev/null' =>
                     sequence([ policy_text('amdgpu-dkms', '(none)', $NEW), 0 ], $o{policy}), 0 ] : () ) ) : () ),
      ( $apt ? () : (
        [ qr{^rpm -q amdgpu-dkms 2>&1$} => sequence([ 'package amdgpu-dkms is not installed', 1 ], [ 'amdgpu-dkms', 0 ]), 0 ],
        [ qr{^rpm -q (?:kernel-\S+) 2>&1$} => 'ok', 0 ],
        [ qr{^dnf -q repoquery --available } => 'x-0:1.noarch', 0 ],
      ) ),
    ]);
  my $conn = Local::FakeConn->new;
  my $how;
  @SLEPT = ();
  my $rec = record_host(
    host => $host,
    subs => { 'Rex::get_current_connection' => sub { return { conn => $conn } } },
    code => sub { $how = Rex::GPU::AMD::install_driver(gpus => [ gpu_mi300x() ], method => 'dkms') },
  );
  return ( $rec, $how );
}

sub no_pkg { my ( $rec ) = @_; return !grep { /^pkg:/ } @{ $rec->{lines} } }

my $MAKE_LOG = '/var/lib/dkms/amdgpu/*/build/make.log';
sub unheld_message {
  my ( $kernel ) = @_;
  return "install_driver: amdgpu-dkms is installed, but dkms reports no amdgpu module built and installed for kernel $kernel; see $MAKE_LOG";
}
sub held_message {
  my ( $kernel ) = @_;
  return "install_driver: amdgpu-dkms is installed, but dkms reports no amdgpu module built and installed for kernel $kernel; "
    ."amdgpu-dkms is on hold, and apt-get install -y does not change a held package (where it would have to, it aborts the install). "
    ."Run apt-mark unhold amdgpu-dkms and install_driver again; if the module is still missing then, see $MAKE_LOG";
}

#### held, nothing built

for my $os (qw( ubuntu-24.04 debian-13 debian-12 )) {
  subtest "$os: amdgpu-dkms on hold, no module built: the message names the hold and the way out" => sub {
    # k108: held BELOW the candidate -- apt would have to change it: in the way
    my ( $rec ) = dkms_install($os, built => 0, dpkg => 'hi', status => 'hold ok installed',
      policy => [ policy_text('amdgpu-dkms', $OLD, $NEW), 0 ]);
    my $err = $rec->{error} // '';
    is($err, held_message(os_kernel($os)), 'the full message');
    like($err, qr/is on hold/, '... names the hold');
    like($err, qr/apt-mark unhold amdgpu-dkms/, '... gives apt-mark unhold amdgpu-dkms');
    like($err, qr{\Q$MAKE_LOG\E}, '... still points at make.log');
    is(held_queries($rec), 1, 'the hold is asked once, with dpkg-query');
    is(scalar(hold_policy_lines($rec)), 1, '... and installed against candidate once, with apt-cache policy (k108)');
    ok(!( grep { $_ eq 'run: modprobe amdgpu' } @{ $rec->{lines} }), 'dies before any modprobe');
    ok(no_pkg($rec), 'no pkg: line');
    ok(!$rec->{trapped}, 'no unmocked Rex function reached');
  };
}

subtest 'a hold on a package dpkg does not have installed counts as the selection, too' => sub {
  my ( $rec ) = dkms_install('ubuntu-24.04', built => 0, dpkg => 'hi', status => 'hold ok not-installed');
  is($rec->{error}, held_message(os_kernel('ubuntu-24.04')), 'the hold message');
};

#### not held, nothing built: the old message, unchanged

for my $os (qw( ubuntu-24.04 debian-13 debian-12 )) {
  subtest "$os: amdgpu-dkms not on hold, no module built: the old message, word for word" => sub {
    my ( $rec ) = dkms_install($os, built => 0, dpkg => 'ii', status => 'install ok installed');
    is($rec->{error}, unheld_message(os_kernel($os)), 'exactly the old message');
    unlike($rec->{error} // '', qr/hold/, '... no word about a hold');
    is(held_queries($rec), 1, 'the hold was asked, and answered no');
    ok(no_pkg($rec), 'no pkg: line');
    ok(!$rec->{trapped}, 'no unmocked Rex function reached');
  };
}

#### held, module built: the hold is not asked

subtest 'amdgpu-dkms on hold, but the module is built: lives, no dpkg-query for amdgpu-dkms' => sub {
  for my $os (qw( ubuntu-24.04 debian-13 )) {
    my ( $rec, $how ) = dkms_install($os, built => 1, dpkg => 'hi', status => 'hold ok installed');
    is($rec->{error}, undef, "$os: lives");
    is($how, 'dkms', '... returns dkms');
    is(held_queries($rec), 0, '... the hold is never asked (the question belongs on the failure path)');
    ok(no_pkg($rec), '... no pkg: line');
  }
};

#### RHEL: no hold concept, old message, no dpkg-query

subtest 'rhel-9: no module built: the old message, no dpkg-query at all' => sub {
  my ( $rec ) = dkms_install('rhel-9', built => 0);
  is($rec->{error}, unheld_message(os_kernel('rhel-9')), 'exactly the old message');
  is(scalar(grep { /dpkg-query/ } @{ $rec->{lines} }), 0, 'no dpkg-query');
  ok(no_pkg($rec), 'no pkg: line');
  ok(!$rec->{trapped}, 'no unmocked Rex function reached');
};

#### k101: verify_packages names the hold when a package is missing after the install

my $VERIFY = ' not installed after apt-get install -- check the apt output';
my $BUILD  = "a failed DKMS build leaves it half-configured ($MAKE_LOG)";
my $HOLD   = '; amdgpu-dkms is on hold, and apt-get install -y does not change a held package (where it would have to, it aborts the install). Run apt-mark unhold amdgpu-dkms and install_driver again';

sub verify_held_message { my ( $pkg ) = @_; return "$pkg$VERIFY$HOLD".( $pkg eq 'amdgpu-dkms' ? "; if it is still not installed then, $BUILD" : '' ) }
sub verify_old_message  { my ( $pkg ) = @_; return "$pkg$VERIFY".( $pkg eq 'amdgpu-dkms' ? "; $BUILD" : '' ) }

for my $os (qw( ubuntu-24.04 debian-13 debian-12 )) {
  my $headers = 'linux-headers-'.os_kernel($os);

  subtest "$os: k101 amdgpu-dkms held and not installed: hold first, make.log after" => sub {
    my ( $rec ) = dkms_install($os, built => 0, dpkg => 'un', status => 'hold ok not-installed');
    is($rec->{error}, verify_held_message('amdgpu-dkms'), 'the full message');
    like($rec->{error}, qr/apt-mark unhold amdgpu-dkms.*; if it is still not installed then, .*\Q$MAKE_LOG\E/s, '... apt-mark unhold, then make.log');
    is(held_queries($rec), 1, 'the hold is asked exactly once');
    ok(!( grep { $_ eq 'run: modprobe amdgpu' } @{ $rec->{lines} }), 'dies before any modprobe');
    ok(no_pkg($rec), 'no pkg: line');
    ok(!$rec->{trapped}, 'no unmocked Rex function reached');
  };

  for my $case ([ 'hold ok not-installed' => undef ], [ 'hold ok installed' => '1:6.14.14-2204561.24.04' ]) {
    my ( $status, $version ) = @$case;
    subtest "$os: k101 header package missing, amdgpu-dkms '$status': hold named, no make.log" => sub {
      my ( $rec ) = dkms_install($os, built => 0, dpkg => 'hi', headers => 'un', status => $status, version => $version,
        # k108: the installed version is below the candidate; `hold ok not-installed` is never asked about
        policy => [ policy_text('amdgpu-dkms', $version // $OLD, $NEW), 0 ]);
      is($rec->{error}, verify_held_message($headers), 'the full message');
      like($rec->{error}, qr/\A\Q$headers\E not installed/, '... names the header package');
      unlike($rec->{error}, qr/make\.log|DKMS build/, '... no make.log hint');
      is(held_queries($rec), 1, 'the hold is asked exactly once');
      ok(no_pkg($rec), 'no pkg: line');
      ok(!$rec->{trapped}, 'no unmocked Rex function reached');
    };
  }

  subtest "$os: k101 not held, a package missing: the old message, word for word" => sub {
    my ( $rec ) = dkms_install($os, built => 0, dpkg => 'un', status => 'install ok not-installed');
    is($rec->{error}, verify_old_message('amdgpu-dkms'), 'amdgpu-dkms missing: exactly the old message');
    ( $rec ) = dkms_install($os, built => 0, dpkg => 'ii', headers => 'un', status => 'install ok installed');
    is($rec->{error}, verify_old_message($headers), 'header package missing: exactly the old message');
    ok(no_pkg($rec), 'no pkg: line');
  };

  # kept apart from the message claims: those hold before k101, this one does not
  subtest "$os: k101 not held, a package missing: the hold is asked once, and answered no" => sub {
    my ( $rec ) = dkms_install($os, built => 0, dpkg => 'un', status => 'install ok not-installed');
    is(held_queries($rec), 1, 'amdgpu-dkms missing: one dpkg-query');
    ( $rec ) = dkms_install($os, built => 0, dpkg => 'ii', headers => 'un', status => 'install ok installed');
    is(held_queries($rec), 1, 'header package missing: one dpkg-query');
  };
}

subtest 'k101: everything installed, amdgpu-dkms held: verify asks nothing new' => sub {
  my ( $rec, $how ) = dkms_install('ubuntu-24.04', built => 1, dpkg => 'hi', status => 'hold ok installed');
  is($rec->{error}, undef, 'lives');
  is(held_queries($rec), 0, 'no dpkg-query for amdgpu-dkms');
};

subtest 'k101: an inbox plan with a held amdgpu-dkms on the host: old message, no hold question' => sub {
  my $os = 'debian-13';
  my $host = amd_host($os,
    state => [ fresh() ], module => 'inbox',
    responses => [
      dpkg_l('firmware-amd-graphics' => 'un'),
      dpkg_query('hold ok installed'),
      [ 'LC_ALL=C apt-cache policy firmware-amd-graphics 2>/dev/null' =>
        "firmware-amd-graphics:\n  Installed: (none)\n  Candidate: 20250410-2\n  Version table:\n", 0 ],
    ]);
  my $rec = record_host(
    host => $host,
    subs => { 'Rex::get_current_connection' => sub { return { conn => Local::FakeConn->new } } },
    code => sub { Rex::GPU::AMD::install_driver(gpus => [ gpu_mi300x() ], method => 'inbox') },
  );
  is($rec->{error}, "firmware-amd-graphics$VERIFY", 'the old message, nothing appended');
  is(held_queries($rec), 0, 'no dpkg-query for amdgpu-dkms');
  ok(( grep { /apt-get .* install -y / } @{ $rec->{lines} }), 'the inbox install did run (the plan had a package to verify)');
  ok(no_pkg($rec), 'no pkg: line');
  ok(!$rec->{trapped}, 'no unmocked Rex function reached');
};

subtest 'k101 rhel-9: a package missing after dnf install: no dpkg-query, no pkg:' => sub {
  my ( $rec ) = dkms_install('rhel-9', built => 0);
  is(scalar(grep { /dpkg-query/ } @{ $rec->{lines} }), 0, 'no dpkg-query');
  ok(no_pkg($rec), 'no pkg: line');
  ok(!$rec->{trapped}, 'no unmocked Rex function reached');
};

#### k108: which holds are named, and when
#
# The message pieces, spelled out here (not taken from the code): one sentence
# names the holds and the way out, then post_install's make.log hint or
# verify_packages' build-log hint.

sub hold_sentence {
  my ( @held ) = @_;
  my $names = @held > 1 ? join(', ', @held[0 .. $#held - 1]).' and '.$held[-1] : $held[0];
  return $names.( @held > 1 ? ' are' : ' is' ).' on hold, and apt-get install -y does not change a held package '
    .'(where it would have to, it aborts the install). Run apt-mark unhold '.join(' ', @held).' and install_driver again';
}
# post_install's die (module not built), with or without a hold sentence
sub built_message {
  my ( $os, @held ) = @_;
  my $kernel = os_kernel($os);
  return "install_driver: amdgpu-dkms is installed, but dkms reports no amdgpu module built and installed for kernel $kernel; "
    .( @held ? hold_sentence(@held)."; if the module is still missing then, " : '' )."see $MAKE_LOG";
}
# verify_packages' die for $pkg, with or without a hold sentence
sub missing_message {
  my ( $pkg, @held ) = @_;
  my $build = $pkg eq 'amdgpu-dkms' ? $BUILD : undef;
  my $tail = @held ? '; '.hold_sentence(@held).( defined $build ? "; if it is still not installed then, $build" : '' )
           : defined $build ? "; $build" : '';
  return "$pkg$VERIFY$tail";
}
sub count_lines { my ( $rec, $re ) = @_; return scalar grep { /$re/ } @{ $rec->{lines} } }

my $UBUNTU = 'ubuntu-24.04';
my $HDR    = 'linux-headers-'.os_kernel($UBUNTU);
my $FW     = 'amdgpu-dkms-firmware';
my @BELOW  = ( policy => [ policy_text('amdgpu-dkms', $OLD, $NEW), 0 ] );   # installed below the candidate
my @AT     = ( policy => [ policy_text('amdgpu-dkms', $NEW, $NEW), 0 ] );   # installed at the candidate

subtest 'k108 claim 1: held, installed BELOW the candidate, no module: the hold is named' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hi', status => 'hold ok installed', @BELOW);
  is($rec->{error}, built_message($UBUNTU, 'amdgpu-dkms'), 'post_install names the hold');
  is_deeply([ hold_policy_lines($rec) ], [ 'run: LC_ALL=C apt-cache policy amdgpu-dkms 2>/dev/null' ],
    'one apt-cache policy after the install: amdgpu-dkms only, LC_ALL=C, stderr dropped');
  is_deeply([ grep { /dpkg-query .*amdgpu-dkms/ } @{ $rec->{lines} } ],
    [ q{run: dpkg-query -W -f='${Package} ${Status} ${Version}\n' }."$HDR amdgpu-dkms linux-modules-extra-".os_kernel($UBUNTU)." $FW 2>/dev/null" ],
    'one dpkg-query for every plan package and the firmware');
  ok(no_pkg($rec) && !$rec->{trapped}, 'no pkg: line, no unmocked Rex function');
};

subtest 'k108 claim 2: held AT the candidate, no module: only the make.log text, no hold' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hi', status => 'hold ok installed', version => $NEW, @AT);
  is($rec->{error}, built_message($UBUNTU), 'post_install: the plain message, word for word');
  unlike($rec->{error}, qr/hold/, '... no word about a hold');
  is(scalar(hold_policy_lines($rec)), 1, '... the candidate was compared (that is why the hold is not named)');

  # verify_packages, k101's hF case: the "hold first" claim of t/17-amd-install-driver.t is replaced
  ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hF', status => 'hold ok half-configured', version => $NEW, @AT);
  is($rec->{error}, missing_message('amdgpu-dkms'), 'verify_packages, hF at the candidate: the build-log message only');
  unlike($rec->{error}, qr/hold/, '... no word about a hold');

  # under the candidate it IS named, before the build log
  ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hF', status => 'hold ok half-configured', version => $OLD, @BELOW);
  is($rec->{error}, missing_message('amdgpu-dkms', 'amdgpu-dkms'), 'verify_packages, hF below the candidate: hold first, build log after');
};

subtest 'k108 claim 3: "hold ok not-installed": named, and no policy question' => sub {
  # a policy answer that would say "no obstacle" if it were asked
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'un', status => 'hold ok not-installed', @AT);
  is($rec->{error}, missing_message('amdgpu-dkms', 'amdgpu-dkms'), 'named');
  is(scalar(hold_policy_lines($rec)), 0, 'no apt-cache policy after the install');
};

subtest 'k108 claim 4: header missing, amdgpu-dkms held at the candidate: the old text, no hold' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hi', headers => 'un', status => 'hold ok installed',
    version => $NEW, @AT);
  is($rec->{error}, missing_message($HDR), 'exactly the old message for the header package');
  unlike($rec->{error}, qr/hold/, '... no word about a hold');
  is(scalar(hold_policy_lines($rec)), 1, '... the candidate was compared');
};

subtest 'k108 claim 5: firmware held and not installed: named, no policy question' => sub {
  # amdgpu-dkms went in, no module (post_install): the firmware is the one in the way
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'ii', status => 'install ok installed',
    more => [ "$FW hold ok not-installed" ]);
  is($rec->{error}, built_message($UBUNTU, $FW), 'post_install names the firmware');
  is(scalar(hold_policy_lines($rec)), 0, '... no apt-cache policy after the install');
  # amdgpu-dkms missing (verify_packages)
  ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'un', status => 'install ok not-installed',
    more => [ "$FW hold ok not-installed" ]);
  is($rec->{error}, missing_message('amdgpu-dkms', $FW), 'verify_packages names it, then the build-log hint');
  is(scalar(hold_policy_lines($rec)), 0, '... no apt-cache policy after the install');
};

subtest 'k108 claim 6: the header package held and not installed: named' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'ii', headers => 'un', status => 'install ok installed',
    more => [ "$HDR hold ok not-installed" ]);
  is($rec->{error}, missing_message($HDR, $HDR), 'the header package is named, with its own unhold');
  unlike($rec->{error}, qr/make\.log|DKMS build/, '... no build-log hint (it is not amdgpu-dkms)');
  is(scalar(hold_policy_lines($rec)), 0, '... no apt-cache policy');
};

subtest 'k108 claim 7: firmware held and installed: not named' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'ii', status => 'install ok installed',
    more => [ "$FW hold ok installed 1:6.14.14-2204561.24.04" ]);
  is($rec->{error}, built_message($UBUNTU), 'post_install: the plain message');
  is(scalar(hold_policy_lines($rec)), 0, '... the firmware is never compared against a candidate (any installed version satisfies the dependency)');
  ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'ii', headers => 'un', status => 'install ok installed',
    more => [ "$FW hold ok installed 1:6.14.14-2204561.24.04" ]);
  is($rec->{error}, missing_message($HDR), 'verify_packages: the plain message');
};

subtest 'k108 claim 8: two holds: one sentence, one apt-mark unhold for both' => sub {
  my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'un', status => 'hold ok not-installed',
    more => [ "$FW hold ok not-installed" ]);
  is($rec->{error}, missing_message('amdgpu-dkms', 'amdgpu-dkms', $FW), 'verify_packages: the whole message');
  like($rec->{error}, qr/\Q; amdgpu-dkms and $FW are on hold, \E/, '... one sentence, "X and Y are on hold"');
  like($rec->{error}, qr/\QRun apt-mark unhold amdgpu-dkms $FW and install_driver again\E/, '... one unhold command for both');
  is(scalar(() = $rec->{error} =~ /apt-mark unhold/g), 1, '... said once');
};

subtest 'k108 claim 9: the policy question empty or failed: the hold is named as before k108' => sub {
  for my $case ([ 'empty, exit 0'   => [ '', 0 ] ],
                [ 'empty, exit 100' => [ '', 100 ] ],
                [ 'no Installed/Candidate lines' => [ "N: Unable to locate package amdgpu-dkms\n", 100 ] ],
                [ 'a foreign-architecture block only' => [ policy_text('amdgpu-dkms:i386', $NEW, $NEW), 0 ] ]) {
    my ( $label, $answer ) = @$case;
    # held AT the candidate: with a working policy this would NOT be named
    my ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hi', status => 'hold ok installed', version => $NEW,
      policy => $answer);
    is($rec->{error}, built_message($UBUNTU, 'amdgpu-dkms'), "post_install, $label: named");
    is(scalar(hold_policy_lines($rec)), 1, '... and the policy was asked');
    ( $rec ) = dkms_install($UBUNTU, built => 0, dpkg => 'hF', status => 'hold ok half-configured', version => $NEW,
      policy => $answer);
    is($rec->{error}, missing_message('amdgpu-dkms', 'amdgpu-dkms'), "verify_packages, $label: named");
  }
};

subtest 'k108 claim 10: the install went through: no hold question at all' => sub {
  for my $os (qw( ubuntu-24.04 debian-13 )) {
    my ( $rec, $how ) = dkms_install($os, built => 1, dpkg => 'hi', status => 'hold ok installed',
      more => [ "$FW hold ok not-installed" ], @BELOW);
    is($rec->{error}, undef, "$os: lives");
    is($how, 'dkms', '... dkms');
    is(count_lines($rec, qr/dpkg-query(?!.*pve-firmware)/), 0, '... no dpkg-query (not for the plan, not for the firmware; the Proxmox probe on Debian aside)');
    is(scalar(hold_policy_lines($rec)), 0, '... no apt-cache policy after the install');
  }
};

subtest 'k108 claim 11: post_install and verify_packages say the hold the same way' => sub {
  for my $os (qw( ubuntu-24.04 debian-13 debian-12 )) {
    # one hold: the firmware, not installed
    my @fw = ( more => [ "$FW hold ok not-installed" ] );
    my ( $post )   = dkms_install($os, built => 0, dpkg => 'ii', status => 'install ok installed', @fw);
    my ( $verify ) = dkms_install($os, built => 0, dpkg => 'un', status => 'install ok not-installed', @fw);
    my $one = hold_sentence($FW);
    like($post->{error},   qr/\Q; $one; \E/, "$os, one hold: post_install says it");
    like($verify->{error}, qr/\Q; $one; \E/, "$os, one hold: verify_packages says it");

    # two: amdgpu-dkms held below its candidate, and the firmware
    ( $post )   = dkms_install($os, built => 0, dpkg => 'hi', status => 'hold ok installed', @fw, @BELOW);
    ( $verify ) = dkms_install($os, built => 0, dpkg => 'hF', status => 'hold ok half-configured', @fw, @BELOW);
    my $two = hold_sentence('amdgpu-dkms', $FW);
    like($post->{error},   qr/\Q; $two; \E/, "$os, two holds: post_install says it");
    like($verify->{error}, qr/\Q; $two; \E/, "$os, two holds: verify_packages says it");
  }
};

done_testing;
