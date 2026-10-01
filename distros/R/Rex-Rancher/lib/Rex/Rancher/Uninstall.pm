# ABSTRACT: Take RKE2/K3s and Cilium's datapath off a host, and refuse to install over what Cilium left

package Rex::Rancher::Uninstall;
our $VERSION = '0.003';
use v5.14.4;
use warnings;

use Rex::Commands::Run ();
use Rex::Logger ();
use Rex::Rancher::Distribution;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  uninstall_node
);

# Cilium's datapath outlives the vendor uninstallers (kubernetes-ocp k190,
# measured on ocpt-cp). rke2-uninstall.sh stops the agent but not what the
# agent attached to the kernel: the socket-LB programs on the root cgroup
# (through /run/cilium/cgroupv2), the tc/tcx programs on the host's devices,
# the maps and links pinned in bpffs, the cilium_* devices, the CILIUM_*
# iptables chains and Cilium's policy-routing ip rules. Until a reboot the
# socket LB keeps translating the old cluster's service addresses to pods that
# are gone, so connect() to one of them -- a registry mirror on localhost:30500
# that every containerd is pointed at -- hangs instead of being refused, every
# image pull waits minutes for it, and a fresh RKE2 on the host never gets
# etcd up within its start bound.
#
# One module for both sides of that: the check install_server and
# install_agent run before they touch the host, and the uninstall that clears
# it. Both test the same signals, cilium_residue.


sub distribution_class { 'Rex::Rancher::Distribution' }


sub cilium_residue {
  my ( $self ) = @_;
  my $cgroup = $self->_cilium_cgroup_root;
  return (
    [ '[ -e /sys/fs/bpf/cilium ]',                    '/sys/fs/bpf/cilium' ],
    [ 'grep -qs " '.$cgroup.' " /proc/mounts',         $cgroup ],
    [ 'ip link show dev cilium_host >/dev/null 2>&1', 'cilium_host' ]
  );
}


sub cilium_residue_probe_cmd {
  my ( $self ) = @_;
  return 'if '.$self->_distribution_present_cmd.'; then :; else '
    .join('', map { $_->[0].' && echo '.$_->[1].'; ' } $self->cilium_residue)
    .'fi; true';
}


sub cilium_residue_in {
  my ( $self, $out ) = @_;
  my %name = map { $_->[1] => 1 } $self->cilium_residue;
  return grep { $name{$_} } map { s/\A\s+|\s+\z//gr } split /\n/, $out // '';
}


sub check_cilium_residue {
  my ( $self ) = @_;
  # auto_die => 0: the probe ends in `true`, so a non-zero exit means it did
  # not run; that is warned about below, not mistaken for a clean host.
  my $out   = Rex::Commands::Run::run($self->cilium_residue_probe_cmd, auto_die => 0);
  my $exit  = $? >> 8;
  my @found = $self->cilium_residue_in($out);
  if (!@found) {
    Rex::Logger::info("Could not check this host for Cilium datapath state left by an "
      . "earlier cluster (the probe exited $exit): going on without that check", 'warn')
      if $exit;
    return 1;
  }
  my $labels = $self->_distribution_labels;
  die "This host still carries Cilium datapath state from an earlier cluster ("
    . join(', ', @found) . "), and no $labels is installed on it. Until the host is "
    . "rebooted, Cilium's socket load balancer keeps translating the old cluster's "
    . "service addresses to pods that are gone: connections to them hang instead of "
    . "being refused, a registry mirror among them, so every image pull of the new "
    . "install stalls and it does not come up in time. Nothing was written or "
    . "installed. Reboot the host, then run the install again.\n";
}


sub uninstall_cmd {
  my ( $self ) = @_;
  my @dists  = $self->_distributions;
  my $labels = $self->_distribution_labels;
  return join ' ; ',
    'for u in ' . join(' ', map { $_->uninstall_scripts } @dists) . '; do'
      . ' if command -v $u >/dev/null 2>&1; then $u 2>/dev/null || true; fi;'
      . ' done',
    ( map { $self->_env_files_cmd($_) } @dists ),
    # --one-file-system: /run/k3s holds containerd's task mounts, a pod's
    # hostPath bind among them; one the uninstaller left mounted is skipped,
    # never recursed into.
    'rm -rf --one-file-system ' . join(' ', $self->_leftover_paths) . ' 2>/dev/null || true',
    $self->_cilium_cleanup_cmd,
    'for t in ' . join(' ', $self->_cilium_ip_tables)
      . '; do while ip rule del lookup $t 2>/dev/null; do :; done; done',
    # Back at priority 0 first, then the relocated one goes -- never the
    # other way round, or the host has no local-table lookup in between.
    'ip rule list 2>/dev/null | grep -qE "^0:[[:space:]].*lookup local"'
      . ' || ip rule add from all lookup local priority 0 2>/dev/null || true',
    'ip rule list 2>/dev/null | grep -qE "^0:[[:space:]].*lookup local"'
      . ' && ip rule del from all lookup local priority 100 2>/dev/null || true',
    # Every step above is guarded, so without this the line exited 0
    # whatever happened -- a missing or failing uninstaller left rke2 in
    # place and read as a clean uninstall (kubernetes-ocp k175).
    'still=""',
    'for b in ' . join(' ', map { $_->binary } @dists) . ';'
      . ' do p=$(command -v $b 2>/dev/null) && still="$still $p"; done',
    'if [ -n "$still" ]; then echo "' . $labels . ' is still installed after the uninstall:$still'
      . ' -- its uninstall script is missing or failed" >&2; exit 1; fi',
    # And the datapath: a host whose Cilium state survived hangs the next
    # install on it. Only a reboot clears what is left.
    'left=""',
    ( map { $_->[0] . ' && left="$left ' . $_->[1] . '"' } $self->cilium_residue ),
    'if [ -n "$left" ]; then echo "Cilium datapath state is still on the host after the uninstall:$left'
      . ' -- reboot the host before ' . $labels . ' is installed on it again" >&2; exit 1; fi';
}


sub uninstall_warnings {
  my ( $self, @output ) = @_;
  my $marker = $self->_warning_marker;
  return map { /\A\Q$marker\E:\s*(\S.*)\z/ ? $1 : () }
    map { s/\A\s+|\s+\z//gr } map { split /\n/ } grep { defined } @output;
}


sub uninstall_failure {
  my ( $self, $exit, $stderr ) = @_;
  return unless $exit;
  my $marker = $self->_warning_marker;
  my $why = join "\n", grep { !/\A\s*\Q$marker\E:/ } split /\n/, $stderr // '';
  $why =~ s/\s+\z//;
  return "Uninstall of " . $self->_distribution_labels . " failed (exit $exit)"
    . ( length $why ? ": $why" : '' ) . "\n";
}


sub uninstall_node {
  my $self = __PACKAGE__;
  Rex::Logger::info("Uninstalling " . $self->_distribution_labels
    . " and clearing Cilium's datapath from this host");
  my ( $stdout, $stderr ) = ( '', '' );
  # auto_die => 0: the exit status and stderr make the message below.
  Rex::Commands::Run::run($self->uninstall_cmd,
    sub { my ( $out, $err ) = @_; $stdout = $out // ''; $stderr = $err // ''; return $out },
    auto_die => 0);
  my $exit = $? >> 8;
  Rex::Logger::info($_, 'warn') for $self->uninstall_warnings($stdout, $stderr);
  my $failure = $self->uninstall_failure($exit, $stderr);
  die $failure if defined $failure;
  Rex::Logger::info($self->_distribution_labels . " uninstalled, no Cilium datapath state left");
  return 1;
}

#
# What the lines above are made of
#

# Every distribution, the default first, as unknown_distribution lists them.
sub _distributions {
  my ( $self ) = @_;
  my $class   = $self->distribution_class;
  my $default = $class->default_distribution;
  return map { $class->new_for($_) }
    $default, sort grep { $_ ne $default } keys %{ $class->distribution_classes };
}

sub _distribution_labels {
  my ( $self ) = @_;
  return join '/', map { $_->label } $self->_distributions;
}

# A distribution is there: its binary on PATH, or one of its units active
# (systemctl is-active is true when any of the units named is).
sub _distribution_present_cmd {
  my ( $self ) = @_;
  my @dists = $self->_distributions;
  return join ' || ',
    ( map { 'command -v ' . $_->binary . ' >/dev/null 2>&1' } @dists ),
    'systemctl is-active --quiet '
      . join(' ', map { ( $_->server_service, $_->agent_service ) } @dists)
      . ' 2>/dev/null';
}

# The PATH file ensure_nvidia_runtime_path writes for the NVIDIA runtime
# lookup, which no vendor uninstaller removes (kubernetes-ocp, a GPU host
# after destroy). The line also runs on hosts Rex::Rancher did not set up, so
# a file goes only when it is exactly what is written on a host without one:
# runtime_path_line and nothing else ($(...) drops trailing newlines). A file
# with anything more is the admin's and stays whole, our PATH line in it too:
# whatever PATH that line replaced is gone, so editing it out restores
# nothing. Recognised by content, not a marker: the file is in restart_watch,
# and adding one to it would restart rke2 on every node's next run. And only
# once the distribution's binary is gone, since its units read the file (the
# outcome check reports a binary that stayed). K3s has no env files: no step.
sub _env_files_cmd {
  my ( $self, $dist ) = @_;
  my @files = $dist->env_files or return;
  return 'command -v ' . $dist->binary . ' >/dev/null 2>&1 || for f in ' . join(' ', @files) . ';'
    . ' do if [ -f $f ] && [ "$(cat $f 2>/dev/null)" = "' . $dist->runtime_path_line . '" ];'
    . ' then rm -f $f 2>/dev/null || true; fi; done';
}

# What the vendor uninstallers stop short of: the Cilium CLI
# (Rex::Rancher::Cilium installs it), the CNI directory (Cilium's cni.binPath,
# /opt/cni/bin, on both distributions) and the runtime dir RKE2 and K3s share.
# A stale cilium binary is not cosmetic: install_cilium keeps a CLI whose
# version happens to match instead of installing the one asked for.
sub _leftover_paths { qw( /usr/local/bin/cilium /opt/cni /run/k3s ) }

# A warning is one line on stderr, starting with the marker, so that
# uninstall_warnings finds it among whatever else the channel carries. The
# text goes between double quotes: no ", $, ` or backslash in it -- and no
# single quote, which the line as a whole has none of.
sub _warning_marker { 'rex-rancher-uninstall-warning' }

sub _warning_cmd {
  my ( $self, $text ) = @_;
  # || true: a warning that cannot be written must not fail the line.
  return 'echo "' . $self->_warning_marker . ': ' . $text . '" >&2 || true';
}

# Cilium's proxy route tables (2004 to-proxy, 2005 from-proxy); nothing else
# uses these table ids.
sub _cilium_ip_tables { ( 2004, 2005 ) }

sub _cilium_pins        { qw( /sys/fs/bpf/cilium /sys/fs/bpf/tc/globals/cilium_* ) }
sub _cilium_cgroup_root { '/run/cilium/cgroupv2' }
sub _cilium_run_dir     { '/run/cilium' }
sub _cilium_links       { qw( cilium_host cilium_net cilium_vxlan cilium_geneve cilium_wg0 ) }
sub _iptables {
  qw( iptables ip6tables iptables-legacy ip6tables-legacy iptables-nft ip6tables-nft )
}

# The way Cilium's own post-uninstall cleanup clears it, without bpftool (not
# on the hosts) and without the agent's image:
#
#   - pinned objects: Cilium attaches its cgroup and tcx programs as bpf_links
#     (kernel 5.7+) and pins the links under /sys/fs/bpf/cilium so they
#     survive the agent. Unpinning the last reference -- the agent is gone --
#     releases the link, and the kernel detaches the program: the rm IS the
#     detach;
#   - legacy tc attachments (kernel without tcx): the clsact qdisc of every
#     device that carries a Cilium program goes, and its filters with it;
#   - Cilium's devices, and its iptables chains in every backend present:
#     jumps into them deleted, then flushed and removed, in one restore
#     transaction per table;
#   - the cgroup2 mount, then Cilium's runtime dir -- with --one-file-system,
#     so a mount that refused to go is never recursed into.
#
# A tool the tc or the iptables step needs that is missing skips that step
# with a warning, not silently: tc is not in Rocky's/RHEL's base (it comes
# with iproute-tc), and a host may have no iptables tools at all while
# Cilium's own container wrote the chains.
#
# Taken over as kubernetes-ocp runs it (OCP::Role::Provider::ExistingHost).
sub _cilium_cleanup_cmd {
  my ( $self ) = @_;
  my $cgroup = $self->_cilium_cgroup_root;
  return join ' ; ',
    'if command -v tc >/dev/null 2>&1; then'
      . ' for d in /sys/class/net/*; do d=${d##*/};'
      . ' if tc filter show dev $d ingress 2>/dev/null | grep -qE "cil_|bpf_(netdev|host|overlay|lxc)"'
      . ' || tc filter show dev $d egress 2>/dev/null | grep -qE "cil_|bpf_(netdev|host|overlay|lxc)";'
      . ' then tc qdisc del dev $d clsact 2>/dev/null || true; fi; done;'
      . ' else ' . $self->_warning_cmd('tc is not installed: tc attachments Cilium left on the host'
        . ' devices were not checked or removed (on Rocky/RHEL, tc comes with the iproute-tc package);'
        . ' a reboot clears them') . '; fi',
    'rm -rf ' . join(' ', $self->_cilium_pins) . ' 2>/dev/null || true',
    'for l in ' . join(' ', $self->_cilium_links) . '; do ip link del dev $l 2>/dev/null || true; done',
    'ipt_used=""',
    'for ipt in ' . join(' ', $self->_iptables) . '; do'
      . ' command -v $ipt-save >/dev/null 2>&1 && command -v $ipt-restore >/dev/null 2>&1 || continue;'
      . ' ipt_used=1;'
      . ' for tb in filter nat mangle raw; do'
      . ' s=$($ipt-save -t $tb 2>/dev/null) || continue;'
      . ' printf "%s\n" "$s" | grep -qE "^:(OLD_)?CILIUM_" || continue;'
      . ' { echo "*$tb";'
      . ' printf "%s\n" "$s" | grep -E "^-A " | grep -vE "^-A (OLD_)?CILIUM_" | grep -E -- "-j (OLD_)?CILIUM_" | sed "s/^-A /-D /";'
      . ' printf "%s\n" "$s" | sed -nE "s/^:((OLD_)?CILIUM_[^ ]*) .*/-F \1/p";'
      . ' printf "%s\n" "$s" | sed -nE "s/^:((OLD_)?CILIUM_[^ ]*) .*/-X \1/p";'
      . ' echo COMMIT; } | $ipt-restore --noflush 2>/dev/null || true;'
      . ' done; done',
    '[ -n "$ipt_used" ] || ' . $self->_warning_cmd('no iptables backend with both -save and -restore'
      . ' is installed: the CILIUM_* iptables chains Cilium left were not checked or removed;'
      . ' a reboot clears them'),
    "umount $cgroup 2>/dev/null || umount -l $cgroup 2>/dev/null || true",
    'rm -rf --one-file-system ' . $self->_cilium_run_dir . ' 2>/dev/null || true';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Uninstall - Take RKE2/K3s and Cilium's datapath off a host, and refuse to install over what Cilium left

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Uninstall;

  # Take RKE2/K3s and Cilium's datapath off the host (destructive)
  task 'wipe', 'old-node.example.com', sub {
    uninstall_node();
  };

  # The same line through another channel than Rex
  my $cmd = Rex::Rancher::Uninstall->uninstall_cmd;
  my $r   = $my_ssh->run($cmd);
  warn "$_\n" for Rex::Rancher::Uninstall->uninstall_warnings($r->{stdout}, $r->{stderr});
  die Rex::Rancher::Uninstall->uninstall_failure($r->{exit}, $r->{stderr})
    if $r->{exit};

  # Refuse a host Cilium left state on, before preparing it
  Rex::Rancher::Uninstall->check_cilium_residue;

=head1 DESCRIPTION

Cilium's datapath outlives the vendor uninstall scripts. C<rke2-uninstall.sh>
and C<k3s-uninstall.sh> stop the agent, but not what it attached to the
kernel: the socket load balancer on the root cgroup, tc programs, maps and
links pinned in bpffs, the C<cilium_*> devices, iptables chains and ip
rules. Until the host is rebooted, the socket load balancer keeps
translating the old cluster's service addresses to pods that are gone, so a
connection to one of them hangs instead of being refused. When that address
is a registry mirror, every image pull of a new install on the host stalls
for minutes, and RKE2 misses its start deadline without saying why.

L</check_cilium_residue> is the guard L<Rex::Rancher::Server/install_server>
and L<Rex::Rancher::Agent/install_agent> run first: a host with that state
and no RKE2 or K3s on it is refused before anything is written. With a
distribution on the host the state belongs to its running cluster (a
re-run, an upgrade) and is left alone.

L</uninstall_node> is the other side: it runs the vendor uninstall scripts
and then clears the datapath as Cilium's own cleanup does, and says when a
reboot is still needed -- or, as a warning, when a missing C<tc> or
iptables tool left part of the datapath unchecked. Both test the same
L</cilium_residue>.

Both come from kubernetes-ocp, which measured the problem (a fresh RKE2
after C<rke2-uninstall.sh> without a reboot) and runs the same uninstall
line. Whether the kernel really detaches every program when its pins go has
not been verified live through Rex::Rancher; the outcome check only sees
the pins, the mount and the device.

=head2 distribution_class

C<Rex::Rancher::Distribution>: the class whose
L<Rex::Rancher::Distribution/distribution_classes> say which distributions
are looked for and uninstalled. A subclass may name another one.

=head2 cilium_residue

  my @residue = Rex::Rancher::Uninstall->cilium_residue;
  # ( [ '[ -e /sys/fs/bpf/cilium ]', '/sys/fs/bpf/cilium' ], ... )

What still being on a host means Cilium's datapath outlived its cluster, as
pairs of a shell test (true when it is there) and the name it is reported
by: the pins in C</sys/fs/bpf/cilium>, the cgroup2 mount on
C</run/cilium/cgroupv2> (read from C</proc/mounts>), the C<cilium_host>
device. Pure. The one list both L</check_cilium_residue> (through
L</cilium_residue_probe_cmd>) and the outcome check of L</uninstall_cmd>
test.

=head2 cilium_residue_probe_cmd

The shell line L</check_cilium_residue> runs on the host. Pure. When no
distribution is there -- no L<Rex::Rancher::Distribution/binary> on
C<PATH> and none of their server and agent units active -- it prints the
name of every L</cilium_residue> it finds, one per line; with a distribution
it prints nothing. It only reads, and always exits C<0>.

=head2 cilium_residue_in

  my @found = Rex::Rancher::Uninstall->cilium_residue_in($probe_output);

The L</cilium_residue> names in the output of
L</cilium_residue_probe_cmd>, in the order found; empty for a clean host.
Pure. Only whole lines that are one of those names count: a login banner or
a shell's complaint on the channel is not evidence of Cilium state.

=head2 check_cilium_residue

  Rex::Rancher::Uninstall->check_cilium_residue;

Run L</cilium_residue_probe_cmd> on the host (the exec channel, no SFTP)
and die when it finds anything, naming what it found, what it does to a new
install, and that the host has to be rebooted first. Returns C<1> on a clean
host or one with RKE2 or K3s on it. A probe that cannot run at all (a
non-zero exit with nothing found) only warns that the host was not checked.

L<Rex::Rancher::Server/install_server> and
L<Rex::Rancher::Agent/install_agent> call it before anything is written or
installed; a caller that prepares the node first can call it earlier.

=head2 uninstall_cmd

The shell line L</uninstall_node> runs, for a caller that runs it through
its own channel. Pure. In this order:

=over

=item * every L<Rex::Rancher::Distribution/uninstall_scripts> that is on the
host (C<rke2-uninstall.sh>, C<k3s-uninstall.sh>, C<k3s-agent-uninstall.sh>);
one that fails does not keep the next from running;

=item * the C<PATH> files for the NVIDIA runtime lookup, which
L<Rex::Rancher::Distribution/ensure_nvidia_runtime_path> writes and no
uninstaller removes (L<Rex::Rancher::Distribution/env_files>:
C</etc/default/rke2-server> and C</etc/default/rke2-agent>; K3s has none).
One goes only when it holds nothing but
L<Rex::Rancher::Distribution/runtime_path_line> -- the file written on a
host that had none -- and the distribution's
L<Rex::Rancher::Distribution/binary> is off C<PATH>. A file with anything
else in it is the admin's and stays as it is, our C<PATH> line included, as
does one while the distribution is still installed; neither is a failure;

=item * what the uninstallers leave of Rex::Rancher's and the
distribution's own: the Cilium CLI C</usr/local/bin/cilium>
(L<Rex::Rancher::Cilium> installs it), C</opt/cni> (the CNI binaries,
Cilium's among them), C</run/k3s> (the runtime dir of both distributions),
removed with C<--one-file-system>: a mount the uninstaller left below them
(containerd's task mounts live in C</run/k3s>) is skipped, never recursed
into;

=item * Cilium's datapath: the C<clsact> qdisc of every device carrying a
Cilium tc program (with C<tc> installed, see below); the pins in
C</sys/fs/bpf/cilium> and
C</sys/fs/bpf/tc/globals/cilium_*> (unpinning a link no agent holds any
more is what detaches its program); the devices C<cilium_host>,
C<cilium_net>, C<cilium_vxlan>, C<cilium_geneve>, C<cilium_wg0>; the
C<CILIUM_*> (and C<OLD_CILIUM_*>) iptables chains in every backend present
(C<iptables>, C<ip6tables>, their C<-legacy> and C<-nft> variants): jumps
into them deleted, then flushed and removed, one C<--noflush> restore per
table, every other rule untouched; the C</run/cilium/cgroupv2> mount, then
C</run/cilium> with C<--one-file-system>;

=item * Cilium's ip rules: those looking up tables C<2004> and C<2005>,
then the C<local> table lookup Cilium moved from priority C<0> to C<100>:
put back at C<0> first, and the one at C<100> deleted only once a
priority C<0> one is there, so the host never lacks a C<local> lookup.

=back

Each of those steps is guarded: a step with nothing to do, or a tool that
is not installed, is not a failure. Two missing tools leave part of the
datapath unchecked, and each says so with a warning, one line on stderr
starting with C<rex-rancher-uninstall-warning: >:

=over

=item * no C<tc> (on Rocky/RHEL it comes with the C<iproute-tc> package):
Cilium's legacy tc attachments on the host's devices were not checked or
removed;

=item * no iptables backend with both C<-save> and C<-restore>: the
C<CILIUM_*> chains were not checked or removed.

=back

A reboot clears either. A warning never changes the exit status. What
decides is the outcome, checked last: the line exits C<1> when an
L<Rex::Rancher::Distribution/binary> is still on C<PATH> (C<... is still
installed after the uninstall: PATH>), or when a L</cilium_residue> is
still there (C<Cilium datapath state is still on the host after the
uninstall: NAMES -- reboot the host ...>), with that on stderr.
L</uninstall_warnings> picks the warnings out of the output,
L</uninstall_failure> turns a failed outcome into a message.

C<rke2-uninstall.sh> also removes C</etc/rancher/node>, the node password
with it; the K3s uninstall scripts keep it. For joining the same cluster
again afterwards, see L</uninstall_node>.

=head2 uninstall_warnings

  my @warnings = Rex::Rancher::Uninstall->uninstall_warnings($stdout, $stderr);

The warnings in the output of L</uninstall_cmd>, in the order written,
each its text without the marker, trimmed; empty when every cleanup step
could run. Pure. Takes any number of outputs -- pass stdout and stderr: the
line writes its warnings to stderr, a channel with a pty merges them into
stdout. Only whole lines starting with C<rex-rancher-uninstall-warning: >
and a text count; the vendor uninstallers' output, a login banner, a
shell's complaint or a C<set -x> trace are not warnings.

Warnings are not a failure: the exit status alone decides that (see
L</uninstall_failure>). L</uninstall_node> logs them; a caller running the
line through its own channel reports them there.

=head2 uninstall_failure

  my $message = Rex::Rancher::Uninstall->uninstall_failure($exit, $stderr);

The message for an L</uninstall_cmd> that exited C<$exit> with C<$stderr>,
ending in a newline; nothing for exit C<0>, warnings or not. Pure. The
warning lines (see L</uninstall_warnings>) are not part of the reason.

=head2 uninstall_node

  uninstall_node();

Take RKE2 and K3s, server or agent, off the current host and clear what
Cilium left in the kernel: runs L</uninstall_cmd> over the exec channel (no
SFTP) and returns C<1> when the host is clean afterwards. B<Destructive>:
the distribution's data (C</var/lib/rancher>, etcd with it) goes with its
uninstall script, and Cilium's devices, iptables chains, tc attachments and
ip rules are removed, as is the C</etc/default/rke2-server> or
C<-agent> file Rex::Rancher wrote for the NVIDIA runtime -- only when it
holds nothing but that C<PATH> line; an admin's file stays (see
L</uninstall_cmd>). It runs only when called; no install function calls
it.

Logs every L</uninstall_warnings> as a warning -- no C<tc> on the host, or
no iptables backend with both C<-save> and C<-restore>, so that part of
the datapath was not checked or removed; a reboot clears it. A warning
does not fail it.

Dies with L</uninstall_failure> when RKE2 or K3s is still installed
afterwards (an uninstall script missing or failing), or when Cilium's
datapath state survived: that host needs a reboot before anything is
installed on it again, or L<Rex::Rancher::Server/install_server> and
L<Rex::Rancher::Agent/install_agent> refuse it (see
L</check_cilium_residue>). Running it on a host with nothing installed
changes nothing and returns C<1>.

Joining the host to the same cluster again afterwards, under the same node
name: C<rke2-uninstall.sh> removes C</etc/rancher/node>, and the node
password in it, so the new RKE2 registers with a new password, which the
cluster refuses (C<Node password rejected>) while it keeps the old one's
hash in the secret C<kube-system/NODE.node-password.rke2>. Delete the node
from the cluster, which takes that secret with it, or the secret itself,
before the host joins again. Nothing here does that. The K3s uninstall
scripts leave C</etc/rancher/node> in place: a K3s node rejoins with the
password it had.

=head1 SEE ALSO

L<Rex::Rancher>, L<Rex::Rancher::Server>, L<Rex::Rancher::Agent>,
L<Rex::Rancher::Cilium>, L<Rex::Rancher::Distribution>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-rancher/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
