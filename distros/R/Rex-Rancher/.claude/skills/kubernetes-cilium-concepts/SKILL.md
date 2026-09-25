---
name: kubernetes-cilium-concepts
description: "Use on a Cilium cluster — eBPF networking, kube-proxy replacement, CiliumNetworkPolicy, Gateway API, LB-IPAM, Hubble, or misbehaving service routing and LoadBalancer IPs."
user-invocable: true
---

# Cilium — Concepts Reference

Cilium is an eBPF-based CNI that replaces a whole stack of separate
components. On a Cilium cluster, expect these jobs to be Cilium's, not a
second tool's: pod networking (CNI), kube-proxy (eBPF service routing),
NetworkPolicy incl. L7, encryption (WireGuard), ingress (Gateway API
implementation), service-mesh features, and observability (Hubble). If a
cluster runs Cilium and also nginx-ingress or Istio, that is a decision to
question, not a given.

## kube-proxy replacement

With `kubeProxyReplacement=true` (Helm) the distribution's kube-proxy must be
disabled (RKE2: `disable-kube-proxy: true`) and **all** Service routing is
done by eBPF programs — there are no iptables service rules to inspect.
Debugging shifts accordingly: `cilium-dbg` inside the agent pod and Hubble
flows replace iptables tracing. `kubectl -n kube-system exec ds/cilium --
cilium-dbg status` is the first health check.

## Gateway API

Cilium implements Gateway API (`gatewayClassName: cilium`) — the successor
path to Ingress. The Gateway API CRDs are **not** bundled: they must be
installed before Cilium is deployed, at a Gateway API version matching the
Cilium release. Channels shift by version: before v1.5 the standard set is
Gateway, GatewayClass, HTTPRoute, GRPCRoute, ReferenceGrant and TLS/TCP/UDPRoute
are experimental-only; v1.5 moves TLSRoute (v1) to standard, v1.6 also TCP/UDPRoute.
Cilium ≤1.16 requires TLSRoute v1alpha2 (experimental), 1.17–1.19 treat it as
optional, 1.20 requires TLSRoute v1 + BackendTLSPolicy v1. From v1.5 a
`safe-upgrades` admission policy refuses experimental CRDs over standard ones,
so a standard cluster cannot move to experimental. A Gateway resource in
`kube-system` with HTTP/HTTPS listeners plus HTTPRoutes replaces the
ingress-controller-plus-Ingress pattern.

## LB-IPAM and L2 announcements (bare metal)

On bare metal there is no cloud LoadBalancer provisioner; Cilium fills the
gap with two CRDs:

- `CiliumLoadBalancerIPPool` — the CIDR blocks LB-IPAM may assign to
  `type: LoadBalancer` Services (single-node clusters: the node IP as
  a `/32`).
- `CiliumL2AnnouncementPolicy` — announces assigned IPs via ARP on matching
  interfaces (`externalIPs: true`, `loadBalancerIPs: true`).

Both are `cilium.io/v2alpha1`. Without the announcement policy, Services get
an IP that nothing on the network can reach — the pool alone is not enough.

## Operator CRD timing

The Cilium operator registers its CRDs **asynchronously** after install.
Applying a `CiliumLoadBalancerIPPool` (or any `cilium.io` resource)
immediately after the Helm release succeeds can fail with "no matches for
kind". Automation must wait for the CRD to exist (poll
`customresourcedefinitions` for `ciliumloadbalancerippools.cilium.io` or
`kubectl wait --for condition=established crd/...`) before applying
instances.

## Network policy

`CiliumNetworkPolicy` extends the stock NetworkPolicy model: identity-based
(labels, not IPs), L7-aware (HTTP method/path, Kafka, DNS rules via
`toFQDNs`), plus `CiliumClusterwideNetworkPolicy` for non-namespaced scope.
Stock `NetworkPolicy` resources are also enforced. DNS-based egress policy
requires Cilium to proxy DNS (`toFQDNs` implies a DNS visibility rule).

## Hubble

Hubble is the observability layer over Cilium's eBPF datapath: per-flow
visibility (verdicts, L7 metadata) without sidecars. `hubble observe` for
flows, Hubble Relay for cluster-wide queries, Hubble UI for the service map.
For "policy dropped my traffic" questions, `hubble observe --verdict DROPPED`
is the shortest path to the answer.

## Version coupling

Cilium, the Cilium CLI, and the Gateway API CRD set are three separately
versioned artifacts that must be compatible with each other and the cluster
version. Clusters typically pin all three somewhere central — find and honor
that source of truth rather than bumping one in isolation.

## Related

- `kubernetes-concepts` — the general Kubernetes reference this builds on.
- Cluster repos keep their own skill for site specifics (pinned versions,
  install automation) — this skill stays version-free.
