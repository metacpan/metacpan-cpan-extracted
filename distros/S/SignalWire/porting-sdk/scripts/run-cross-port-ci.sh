#!/usr/bin/env bash
# run-cross-port-ci.sh — top-level CI runner for the porting-sdk audit kit
# itself plus every adjacent ../signalwire-<lang>/ port.
#
# Same script invoked locally (`bash scripts/run-cross-port-ci.sh`) AND by the
# GitHub Actions workflow. No drift between local and CI behavior.
#
# Steps (in order):
#   1. porting-sdk's own pytest suite (mock_signalwire/, mock_relay/, audit_coverage_smoke)
#   2. extract_relay_schemas.py --check (RELAY schemas in sync with Python source)
#   3. For each adjacent ../signalwire-<lang>/, run scripts/run-ci.sh
#   4. Cross-port drift summary (raw drift counts per port)
#   5. Final: ==> CROSS-PORT CI PASS or FAIL (ports: <list>)

set -u
set -o pipefail

PSDK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_ROOT="$(cd "$PSDK_ROOT/.." && pwd)"

# Order matches AUDIT_DISCIPLINE.md / reference_sdk_repos.md.
PORTS="signalwire-python signalwire-typescript signalwire-go signalwire-java signalwire-perl signalwire-ruby signalwire-cpp signalwire-dotnet signalwire-php signalwire-rust"

FAILED_GATES=""
FAILED_PORTS=""

# ---- gate plumbing (identical shape to per-port run-ci.sh) ------------------

run_gate() {
    local name="$1"; shift
    local description="$1"; shift
    local logfile
    logfile="$(mktemp)"
    "$@" >"$logfile" 2>&1
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "[$name] $description ... PASS"
        rm -f "$logfile"
        return 0
    fi
    echo "[$name] $description ... FAIL: exit $rc"
    sed 's/^/    /' "$logfile" | tail -40
    rm -f "$logfile"
    FAILED_GATES="$FAILED_GATES $name"
    return $rc
}

cd "$PSDK_ROOT"

echo "==> running cross-port CI from $PSDK_ROOT"
echo "    (ports root: $SRC_ROOT)"

# ---- step 1: porting-sdk's own pytest suite ---------------------------------

run_gate "PSDK-TESTS" "pytest mock_signalwire mock_relay audit_coverage_smoke" \
    python3 -m pytest --import-mode=importlib \
        tests/mock_signalwire/ tests/mock_relay/ tests/audit_coverage_smoke.py

# ---- step 2: relay schema sync ----------------------------------------------

run_gate "RELAY-SCHEMAS" "extract_relay_schemas.py --check" \
    python3 scripts/extract_relay_schemas.py --check

# ---- step 3: each port's own run-ci.sh --------------------------------------

for port in $PORTS; do
    port_dir="$SRC_ROOT/$port"
    if [ ! -d "$port_dir" ]; then
        echo "[PORT:$port] missing — skipped (clone $port adjacent to porting-sdk)"
        FAILED_PORTS="$FAILED_PORTS $port(missing)"
        continue
    fi
    if [ ! -f "$port_dir/scripts/run-ci.sh" ]; then
        echo "[PORT:$port] no scripts/run-ci.sh — skipped"
        FAILED_PORTS="$FAILED_PORTS $port(no-script)"
        continue
    fi
    echo ""
    echo "----- $port -----"
    if PORTING_SDK="$PSDK_ROOT" bash "$port_dir/scripts/run-ci.sh"; then
        :
    else
        FAILED_PORTS="$FAILED_PORTS $port"
    fi
done

# ---- step 4: cross-port raw drift summary -----------------------------------

echo ""
echo "==> cross-port raw drift summary (filtered drift per port)"
for port in $PORTS; do
    [ "$port" = "signalwire-python" ] && continue
    sigpath="$SRC_ROOT/$port/port_signatures.json"
    if [ ! -f "$sigpath" ]; then
        printf "  %-25s  (port_signatures.json missing)\n" "$port"
        continue
    fi
    omissions="$SRC_ROOT/$port/PORT_OMISSIONS.md"
    additions="$SRC_ROOT/$port/PORT_ADDITIONS.md"
    sigomissions="$SRC_ROOT/$port/PORT_SIGNATURE_OMISSIONS.md"
    args="--reference $PSDK_ROOT/python_signatures.json --port-signatures $sigpath --json"
    [ -f "$omissions" ] && args="$args --surface-omissions $omissions"
    [ -f "$additions" ] && args="$args --surface-additions $additions"
    [ -f "$sigomissions" ] && args="$args --omissions $sigomissions"
    # The diff script exits non-zero when drift > 0, but we still
    # get valid JSON on stdout. Stage to a tempfile so pipefail (set
    # at the top of this script) doesn't make the whole pipeline
    # fail and trigger the "?" fallback.
    tmpjson="$(mktemp)"
    python3 "$PSDK_ROOT/scripts/diff_port_signatures.py" $args >"$tmpjson" 2>/dev/null || true
    drift_count=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("drift",[])))' "$tmpjson" 2>/dev/null || echo "?")
    rm -f "$tmpjson"
    printf "  %-25s  drift=%s\n" "$port" "$drift_count"
done

# ---- step 5: summary --------------------------------------------------------

echo ""
if [ -z "$FAILED_GATES" ] && [ -z "$FAILED_PORTS" ]; then
    echo "==> CROSS-PORT CI PASS"
    exit 0
else
    SUMMARY=""
    [ -n "$FAILED_GATES" ] && SUMMARY="psdk-gates:$FAILED_GATES"
    [ -n "$FAILED_PORTS" ] && SUMMARY="$SUMMARY ports:$FAILED_PORTS"
    echo "==> CROSS-PORT CI FAIL ($SUMMARY)"
    exit 1
fi
