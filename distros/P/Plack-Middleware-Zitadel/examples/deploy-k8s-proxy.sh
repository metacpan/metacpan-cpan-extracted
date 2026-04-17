#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-/storage/raid/home/getty/avatar/.kube/config}"
NAMESPACE="${NAMESPACE:-zitadel}"

kubecfg() {
  KUBECONFIG="$KUBECONFIG_PATH" kubectl "$@"
}

kubecfg get ns "$NAMESPACE" >/dev/null 2>&1 || kubecfg create ns "$NAMESPACE"
kubecfg apply -f "$ROOT_DIR/examples/k8s/configmap.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/deployment.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/service.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/httproute.yaml"
kubecfg -n "$NAMESPACE" rollout status deploy/zitadel-auth-proxy --timeout=240s

echo "Proxy deployed: https://proxy.avatar.conflict.industries/"
