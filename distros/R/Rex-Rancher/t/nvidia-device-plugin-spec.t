use strict;
use warnings;
use Test::More;

use IO::K8s;
use Rex::Rancher::K8s;

# _nvidia_device_plugin_daemonset_spec is a pure function: it returns the
# NVIDIA device-plugin DaemonSet as a plain hashref, which
# deploy_nvidia_device_plugin then hands to $api->new_object(DaemonSet => %{...}).
# It builds no client and touches nothing remote, so it is testable offline —
# no cluster, no kubeconfig, no network, no Kubernetes::REST mock. This guards
# the manifest's load-bearing fields against silent drift; it is the only part
# of K8s.pm reachable without a live API server.
#
# Two layers of coverage below. First: the plain-hashref shape, so a field we
# rely on (image tag, toleration, boolean securityContext, hostPath) cannot be
# renamed or dropped unnoticed. Second: feed that same hashref through the real
# IO::K8s type classes exactly as deploy_nvidia_device_plugin does, so that a
# future IO::K8s tracking a newer Kubernetes — which may make a field we omit
# newly required — fails loudly here instead of on a live deploy.

my $version = 'v0.17.0';
my $ds = Rex::Rancher::K8s::_nvidia_device_plugin_daemonset_spec($version);

is($ds->{metadata}{name}, 'nvidia-device-plugin-daemonset',
  'DaemonSet name');
is($ds->{metadata}{namespace}, 'kube-system',
  'deployed into kube-system');

my $pod = $ds->{spec}{template}{spec};

is($pod->{containers}[0]{image},
  "nvcr.io/nvidia/k8s-device-plugin:$version",
  'image tag interpolates the passed version');

is($pod->{runtimeClassName}, 'nvidia',
  'runtimeClassName nvidia — uses the NVIDIA container runtime to enumerate devices');
is($pod->{priorityClassName}, 'system-node-critical',
  'priorityClassName system-node-critical — scheduled under resource pressure');

is_deeply($pod->{tolerations},
  [{ key => 'nvidia.com/gpu', operator => 'Exists', effect => 'NoSchedule' }],
  'tolerates the nvidia.com/gpu:NoSchedule taint');

is_deeply($pod->{containers}[0]{env},
  [{ name => 'FAIL_ON_INIT_ERROR', value => 'false' }],
  'FAIL_ON_INIT_ERROR=false — starts even if CDI/driver init is incomplete');

my $sc = $pod->{containers}[0]{securityContext};
is(ref $sc->{allowPrivilegeEscalation}, 'SCALAR',
  'allowPrivilegeEscalation is a scalar ref (serialises as a YAML/JSON boolean)');
is(${ $sc->{allowPrivilegeEscalation} }, 0,
  'allowPrivilegeEscalation is false');
is_deeply($sc->{capabilities}, { drop => ['ALL'] },
  'all capabilities dropped');

is($pod->{containers}[0]{volumeMounts}[0]{mountPath},
  '/var/lib/kubelet/device-plugins',
  'device-plugin socket dir mounted');
is($pod->{volumes}[0]{hostPath}{path},
  '/var/lib/kubelet/device-plugins',
  'backed by the kubelet device-plugins hostPath');

# The version is the only thing that varies; a different tag must flow through.
my $pinned = Rex::Rancher::K8s::_nvidia_device_plugin_daemonset_spec('v9.9.9');
is($pinned->{spec}{template}{spec}{containers}[0]{image},
  'nvcr.io/nvidia/k8s-device-plugin:v9.9.9',
  'a custom version reaches the image tag');

# The real construction path. deploy_nvidia_device_plugin hands this hashref to
# $api->new_object(DaemonSet => %{ ... }); Kubernetes::REST delegates new_object
# straight to its inner IO::K8s (same for object_to_struct), so building through
# IO::K8s here is the exact typed-object path — offline, no client, no network.
# This is the assertion that catches required-field drift: if a future IO::K8s
# makes a field the spec omits mandatory, construction dies here, not on a node.
my $k8s = IO::K8s->new;

my $obj = eval { $k8s->new_object(DaemonSet => %{ $ds }) };
ok(!$@, 'new_object(DaemonSet => %$spec) constructs without dying')
  or diag($@);
isa_ok($obj, 'IO::K8s::Api::Apps::V1::DaemonSet',
  'the spec builds the typed DaemonSet class');

# Round-trip back to a struct walks every nested typed object, so a malformed
# child fails loudly here — the same serialisation Kubernetes::REST runs to put
# the manifest on the wire.
my $struct = eval { $k8s->object_to_struct($obj) };
ok(!$@, 'object_to_struct round-trips the DaemonSet without dying')
  or diag($@);
is(ref $struct, 'HASH', 'object_to_struct yields a plain hashref');

done_testing;
