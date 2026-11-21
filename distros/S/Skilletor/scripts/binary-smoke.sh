#!/usr/bin/env bash
# Smoke-test a packed skilletor binary on a clean machine: no perl from the build, no node, no
# toolchain. binary_smoke of the [@Author::GETTY] bundle (dist.ini): its dzil-binary workflow
# runs it from the unpacked dist root on every platform -- Linux inside clean images (AlmaLinux 8
# and 9, Debian bookworm slim) with perl removed, macOS and Windows on the runner as it is -- and
# dzil build runs it after its local pack.
#   scripts/binary-smoke.sh <binary>       from the dist root
# Only the shell's own tools: bash, coreutils, grep, sed, find (the images have no cmp or diff).
#
# Checks: --version prints the dist version ($VERSION in lib/Skilletor.pm); --help starts with
# the usage header; an unknown command exits 2; every ported command (sync, check, status, add,
# trust, source list/remove, available, install, uninstall) on the fixture t/data/smoke/ - local
# sources with templates, skills, an agent and a rule, and an https url source nobody serves -
# and the Claude Code hooks (session-start; user-prompt-submit with nothing due, then due: its
# detached background sync, and the next prompt's pending report; cwd-changed and post-tool-use
# moving into checkouts with a project config) write stdout, stderr, exit codes and files equal
# byte for byte to the transcript t/data/smoke/expected.txt, this run's temp dir written as <work>.
# Then TLS on the machine as it is: a url source on a real public https server (GitHub's archive
# of skilletor's v0.7.0 commit) syncs, and the skill it installs is t/data/smoke/https/SKILL.md
# byte for byte - an exit code alone proves nothing, a failed fetch is a warning.
# t/70-smoke-binary.t runs this script with the Perl CLI from lib/ in place of the binary, so
# the transcript stays what the Perl code writes. A command ported later joins the cases below
# (and the transcript, SKILLETOR_SMOKE_UPDATE=1 prove -l t/70-smoke-binary.t).
#
# Windows (Git Bash): the same checks and transcript. The binary takes Windows paths: the home
# as USERPROFILE and HOME, the hooks' project and inputs in cygpath -m form (C:/Users/...), which
# the transcript writes as <work> as well. The background sync starts through Win32::Process.
#
# SKILLETOR_SMOKE_WAIT: how many seconds the next prompts may wait for the background sync's
# pending report (default 60).
# SKILLETOR_SMOKE_PATH: PATH visible to the binary (default /usr/bin:/bin). Set it to an empty
# directory to prove the packed runtime calls neither a system Perl nor Node.js.
# SKILLETOR_SMOKE_OFFLINE=1 skips the https proof, the one check that needs the network (for
# t/70-smoke-binary.t; never for a binary under test).
#
# SKILLETOR_SMOKE_UPDATE=1 writes the transcript to t/data/smoke/expected.txt instead of
# comparing it - for the Perl CLI from lib/ only, never for a binary under test.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -n "${1:-}" ] || { echo "usage: binary-smoke.sh <binary>" >&2; exit 1; }
[ -f script/skilletor ] && [ -f lib/Skilletor.pm ] && [ -d t/data/smoke ] \
  || fail "run from the dist root"
fixture=$(pwd)/t/data/smoke
[ -f "$1" ] || fail "no such binary: $1"
BIN=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
# An Actions artifact or an HTTP download carries no mode. The bundle's Linux smoke mounts the
# binary read-only, made executable on the host, where a chmod fails: only one that lacks it.
[ -x "$BIN" ] || chmod +x "$BIN"
windows=
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) windows=1 ;; esac

# same_bytes A B: the two files hold the same bytes (CRC and length; the images have no cmp).
same_bytes() { [ "$(cksum <"$1")" = "$(cksum <"$2")" ]; }

# The version the binary must report: the dist's.
want=$(sed -n "s/^our \$VERSION = '\(.*\)';\$/\1/p" lib/Skilletor.pm)
[ -n "$want" ] || fail "cannot read \$VERSION from lib/Skilletor.pm"

# Its physical path (macOS: /private/var/...), the one the hooks print for a checkout in it.
work=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/home/.claude" "$work/home/.codex" "$work/home/.hermes" "$work/cwd" "$work/tmp/par"
: >"$work/gitconfig"

# The binary under a wiped environment, as a user without perl starts it. Every home, harness,
# git and temporary path is inside the work dir; env -i drops the caller's config, project/plugin
# roots, credentials, PERL5LIB and every other ambient value. PAR extracts only below work/tmp.
# Windows needs SYSTEMROOT (Winsock, the crypto RNG), with its paths in native form.
# with_home DIR: envs for the home DIR.
runtime_path=${SKILLETOR_SMOKE_PATH:-/usr/bin:/bin}
if [ -n "$windows" ]; then
  w_tmp=$(cygpath -w "$work/tmp")
  w_gitconfig=$(cygpath -w "$work/gitconfig")
  with_home() {
    local w_home
    w_home=$(cygpath -w "$1")
    envs=(PATH="$runtime_path" SYSTEMROOT="${SYSTEMROOT:-C:\\Windows}" USERPROFILE="$w_home" HOME="$w_home"
          CODEX_HOME="$w_home/.codex" HERMES_HOME="$w_home/.hermes"
          TEMP="$w_tmp" TMP="$w_tmp" TMPDIR="$w_tmp" PAR_GLOBAL_TEMP="$w_tmp/par"
          GIT_CONFIG_GLOBAL="$w_gitconfig" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C)
  }
  # A path as the binary takes it: Windows' own, with forward slashes (JSON needs no escape).
  native() { cygpath -m "$1"; }
else
  with_home() {
    envs=(PATH="$runtime_path" HOME="$1" CODEX_HOME="$1/.codex" HERMES_HOME="$1/.hermes"
          TMPDIR="$work/tmp" TMP="$work/tmp" TEMP="$work/tmp" PAR_GLOBAL_TEMP="$work/tmp/par"
          GIT_CONFIG_GLOBAL="$work/gitconfig" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C)
  }
  native() { printf '%s\n' "$1"; }
fi
with_home "$work/home"
nwork=$(native "$work")
bin() { env -i "${envs[@]}" "$BIN" "$@" </dev/null; }

out=$(bin --version) || fail "--version failed"
[ "$out" = "$want" ] || fail "--version prints '$out', want '$want'"
echo "smoke --version: OK ($out)"

rc=0
bin --help >"$work/help" 2>"$work/help.err" || rc=$?
[ "$rc" -eq 0 ] || fail "--help exits $rc: $(head -c 400 "$work/help.err")"
[ "$(head -n 1 "$work/help")" = "skilletor $want" ] || fail "--help starts with '$(head -n 1 "$work/help")'"
grep -q '^Commands:$' "$work/help" || fail "--help prints no Commands: block"
echo "smoke --help: OK"

rc=0
bin nope >/dev/null 2>"$work/nope.err" || rc=$?
[ "$rc" -eq 2 ] || fail "an unknown command exits $rc, want 2"
[ "$(cat "$work/nope.err")" = "skilletor: unknown command: nope" ] || fail "an unknown command says '$(head -c 400 "$work/nope.err")'"
echo "smoke error path: OK (unknown command, exit 2)"

# The fixture: a home with Claude Code's marker and the user config, its local source at ~/src.
# Every command runs in an empty cwd outside any git work tree (a clean image has no git), so
# its project scope is empty. The hooks' checkouts beside it (no git either) hold the project
# config t/data/smoke/project-config.json, which installs a skill of the user's source.
cp -R "$fixture/src" "$work/home/src"
cp -R "$fixture/extra-src" "$work/home/extra-src"
mkdir -p "$work/home/.claude"
cp "$fixture/user-config.json" "$work/home/.claude/skilletor.json"
printf '{}\n' >"$work/home/.claude.json"
for c in prompted cwd-changed post-tool-use; do
  mkdir -p "$work/checkouts/$c/.claude"
  cp "$fixture/project-config.json" "$work/checkouts/$c/.claude/skilletor.json"
done

: >"$work/transcript"
# capture ARGS...: the command, in the empty cwd; its stdout, stderr and exit code into
# $work/out, $work/err and $work/rc.
capture() {
  local rc=0
  (cd "$work/cwd" && bin "$@") >"$work/out" 2>"$work/err" || rc=$?
  echo "$rc" >"$work/rc"
}
# capture_hook EVENT DIR INPUT: `hook EVENT` as Claude Code runs it, in the session's project
# $work/DIR, CLAUDE_PROJECT_DIR naming it, the event's JSON (the file $work/INPUT) on stdin.
capture_hook() {
  local rc=0
  (cd "$work/$2" && env -i "${envs[@]}" CLAUDE_PROJECT_DIR="$nwork/$2" "$BIN" hook "$1" <"$work/$3") \
    >"$work/out" 2>"$work/err" || rc=$?
  echo "$rc" >"$work/rc"
}
# record LABEL: the last capture, into the transcript.
record() {
  {
    printf '=== %s\n--- stdout\n' "$1"
    cat "$work/out"
    printf -- '--- stderr\n'
    cat "$work/err"
    printf -- '--- exit %s\n' "$(cat "$work/rc")"
  } >>"$work/transcript"
}
# run_case LABEL ARGS...: a command into the transcript; hook_case LABEL EVENT DIR INPUT: a hook.
run_case() { local label=$1; shift; capture "$@"; record "$label"; }
hook_case() { local label=$1; shift; capture_hook "$@"; record "$label"; }
last_ok() {
  local label=$1 rc
  rc=$(cat "$work/rc")
  [ "$rc" -eq 0 ] || fail "$label exits $rc: $(head -c 400 "$work/err")"
}
# files LABEL [DIR]: every file of $work/DIR (default: the home) but skilletor's state dir (it
# holds times), sorted.
files() {
  {
    printf '=== %s\n' "$1"
    (cd "$work/${2:-home}" && find . -path ./.claude/skilletor -prune -o -type f -print | LC_ALL=C sort)
  } >>"$work/transcript"
}

run_case "status before a sync" status
run_case "sync" sync
files "files after the sync"
{
  printf '=== the rendered template: .claude/skills/tpl/SKILL.md\n'
  cat "$work/home/.claude/skills/tpl/SKILL.md" 2>/dev/null || printf '(missing)\n'
} >>"$work/transcript"
run_case "check after a sync (the url source never synced: changed)" check
run_case "check --json" check --json
run_case "status after a sync" status
run_case "status --json" status --json
run_case "sync again" sync
run_case "sync --json again" sync --json
run_case "an option sync does not take (exit 2)" sync --bogus

# Every config command ported after the first binary smoke: a local add (no probe reaches the
# network), explicit trust, listing and reading that source, installing and uninstalling its one
# item, then removing the now-unused source. Guards make update mode refuse a transcript in which
# a command merely printed a plausible error or skipped its edit.
extra_src=$(native "$work/home/extra-src")
run_case "add a local source" add extra "$extra_src"
last_ok "add"
grep -q '^added source extra ' "$work/out" || fail "add did not report the added source"
run_case "trust an existing source" trust loc
last_ok "trust"
grep -q '^trusted source loc (local ' "$work/out" || fail "trust did not report the local backend"
trust_file="$work/home/.claude/skilletor/trust.json"
[ -f "$trust_file" ] || fail "add and trust wrote no trust.json"
grep -q '"extra"' "$trust_file" && grep -q '"loc"' "$trust_file" \
  || fail "trust.json lacks the sources written by add and trust"
{
  printf '=== trust state after add and trust\n'
  cat "$trust_file"
} >>"$work/transcript"
run_case "source list after add" source list
last_ok "source list"
grep -q '^extra \[user\] ' "$work/out" || fail "source list did not show extra"
run_case "available from the added source" available extra
last_ok "available"
grep -q 'skill extra@extra' "$work/out" || fail "available did not show skill extra@extra"
run_case "install from the added source" install skill:extra@extra
last_ok "install"
extra_skill="$work/home/.claude/skills/extra/SKILL.md"
[ -f "$extra_skill" ] || fail "install wrote no .claude/skills/extra/SKILL.md"
{
  printf '=== installed extra skill: .claude/skills/extra/SKILL.md\n'
  cat "$extra_skill"
} >>"$work/transcript"
run_case "uninstall from the added source" uninstall skill:extra@extra
last_ok "uninstall"
[ ! -e "$extra_skill" ] || fail "uninstall left .claude/skills/extra/SKILL.md"
printf '=== extra skill after uninstall\n(absent)\n' >>"$work/transcript"
run_case "remove the added source" source remove extra
last_ok "source remove"
if grep -q '"extra"' "$work/home/.claude/skilletor.json"; then
  fail "source remove left extra in the user config"
fi
printf '=== source extra after removal\n(absent)\n' >>"$work/transcript"

# The hooks' inputs as Claude Code sends them: the session "smoke" starts in the empty cwd and
# moves into two checkouts; the session "smoke-prompted" prompts in a checkout never checked.
printf '{"session_id":"smoke","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}\n' \
  "$nwork/cwd" >"$work/start.json"
printf '{"session_id":"smoke","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"hi"}\n' \
  "$nwork/cwd" >"$work/prompt.json"
printf '{"session_id":"smoke-prompted","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"hi"}\n' \
  "$nwork/checkouts/prompted" >"$work/prompted.json"
printf '{"session_id":"smoke","cwd":"%s","old_cwd":"%s","new_cwd":"%s","hook_event_name":"CwdChanged"}\n' \
  "$nwork/checkouts/cwd-changed" "$nwork/cwd" "$nwork/checkouts/cwd-changed" >"$work/moved.json"
printf '{"session_id":"smoke","cwd":"%s","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cd %s"}}\n' \
  "$nwork/checkouts/post-tool-use" "$nwork/checkouts/post-tool-use" >"$work/bash-cd.json"

hook_case "hook session-start (the check says changed: a sync, the url source's warning)" session-start cwd start.json
hook_case "hook user-prompt-submit (checked at the session start: nothing due)" user-prompt-submit cwd prompt.json
hook_case "hook user-prompt-submit in a checkout never checked (due: the background sync starts)" \
  user-prompt-submit checkouts/prompted prompted.json
# The next prompts there until one hands out the background sync's report, each one before it
# silent. Bounded: a background sync that never ran leaves no report.
wait_s=${SKILLETOR_SMOKE_WAIT:-60}
until_s=$((SECONDS + wait_s))
while :; do
  capture_hook user-prompt-submit checkouts/prompted prompted.json
  [ "$(cat "$work/rc")" = 0 ] && [ ! -s "$work/err" ] \
    || fail "a prompt waiting for the pending report exits $(cat "$work/rc"): $(head -c 400 "$work/err")"
  [ -s "$work/out" ] && break
  [ "$SECONDS" -lt "$until_s" ] || fail "no pending report within $wait_s s: the background sync did not run"
  sleep 0.2
done
record "the next prompt there: the background sync's pending report"
hook_case "hook cwd-changed (into a checkout whose lock does not match its config: synced)" \
  cwd-changed cwd moved.json
hook_case "hook post-tool-use (a cd from the session's start into another checkout: synced)" \
  post-tool-use cwd bash-cd.json
hook_case "hook post-tool-use again (the session's cwd as recorded: nothing to do)" post-tool-use cwd bash-cd.json
files "files at the end"
files "files of the checkouts at the end" checkouts

# This run's temp dir, which the hooks print with a checkout's path (Windows: its native form),
# as <work>.
work_re=$(printf '%s' "$work" | sed 's/[]\/$*.^[]/\\&/g')
nwork_re=$(printf '%s' "$nwork" | sed 's/[]\/$*.^[]/\\&/g')
sed -e "s/$nwork_re/<work>/g" -e "s/$work_re/<work>/g" "$work/transcript" >"$work/transcript.txt"

expected="$fixture/expected.txt"
if [ -n "${SKILLETOR_SMOKE_UPDATE:-}" ]; then
  cp "$work/transcript.txt" "$expected"
  echo "smoke: transcript written to t/data/smoke/expected.txt (review the diff)"
  exit 0
fi
[ -f "$expected" ] || fail "no expectation t/data/smoke/expected.txt"
if ! same_bytes "$work/transcript.txt" "$expected"; then
  if command -v diff >/dev/null 2>&1; then diff -u "$expected" "$work/transcript.txt" | head -n 60 >&2 || true; fi
  fail "ported commands and hooks: the transcript differs from t/data/smoke/expected.txt"
fi
echo "smoke all ported commands and hooks: OK (byte-identical to t/data/smoke/expected.txt)"

# TLS on this machine as it is: its trust store, else the packed Mozilla bundle. A home of its
# own, one url source on GitHub's archive of a fixed commit (its content never changes), its one
# skill installed. sync turns a failed fetch into a warning, so the proof is the installed file.
web_url=https://github.com/Getty/skilletor/archive/c87f6fcb1a3847859cf4ef4923afe3fb85f38d98.tar.gz
if [ -n "${SKILLETOR_SMOKE_OFFLINE:-}" ]; then
  echo "smoke https url source: SKIPPED (SKILLETOR_SMOKE_OFFLINE)"
else
  mkdir -p "$work/web/.claude" "$work/web-cwd"
  printf '{}\n' >"$work/web/.claude.json"
  printf '{\n  "sources": { "web": { "url": "%s" } },\n  "install": { "skills": ["skilletor@web"] }\n}\n' \
    "$web_url" >"$work/web/.claude/skilletor.json"
  with_home "$work/web"
  rc=0
  (cd "$work/web-cwd" && bin sync) >"$work/web.out" 2>"$work/web.err" || rc=$?
  [ "$rc" -eq 0 ] || fail "sync of the https url source exits $rc: $(head -c 400 "$work/web.err")"
  got="$work/web/.claude/skills/skilletor/SKILL.md"
  [ -f "$got" ] || fail "sync of the https url source installed no .claude/skills/skilletor/SKILL.md:" \
    "$(head -c 400 "$work/web.out") $(head -c 400 "$work/web.err")"
  same_bytes "$got" "$fixture/https/SKILL.md" \
    || fail "the skill from the https url source differs from t/data/smoke/https/SKILL.md"
  echo "smoke https url source: OK ($web_url)"
fi
echo "smoke: OK"
