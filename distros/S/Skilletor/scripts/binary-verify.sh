#!/usr/bin/env bash
# Verify a packed skilletor binary against `perl -Ilib script/skilletor` from this dist.
#   scripts/binary-verify.sh <binary>
# binary_verify of the [@Author::GETTY] bundle (dist.ini): run from the dist root right after
# packing, by dzil build's local check and by each platform leg of the bundle's dzil-binary
# workflow. Prints "verify: OK" and exits 0, or "FAIL: <reason>" on STDERR and exits 1. Run it
# where the binary was built (the perl that packed it, with the dist's dependencies): the module
# set it requires inside the archive is computed by scripts/loaded-modules.pl on this host.
# scripts/binary-smoke.sh is the other half: every command and hook on a machine without Perl.
# Nothing reaches the network: the url source is an HTTPS server on 127.0.0.1 with a certificate
# made here, the git source a file:// repository behind insteadOf.
# Windows: the archive checks and --version only; the comparison with perl -Ilib is POSIX-only
# (env -i, POSIX fixture paths), and binary-smoke.sh runs the full transcript there.
set -euo pipefail

[ -n "${1:-}" ] || { echo "usage: binary-verify.sh <binary>" >&2; exit 1; }
BIN=$(perl -MCwd=abs_path -e 'print abs_path(shift) // ""' "$1")
[ -n "$BIN" ] || { echo "FAIL: cannot resolve path: $1" >&2; exit 1; }
[ -x "$BIN" ] || { echo "FAIL: not an executable: $BIN" >&2; exit 1; }
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PERL=$(command -v perl)
work=$(mktemp -d); cache=$(mktemp -d)
server=
cleanup() {
  if [ -n "$server" ]; then kill "$server" 2>/dev/null || true; fi
  rm -rf "$work" "$cache"
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
windows=
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) windows=1 ;; esac
# A path as perl takes it: Strawberry's, C:/... on Windows.
native() { if [ -n "$windows" ]; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
tmo=${SKILLETOR_VERIFY_TIMEOUT:-120}
# timeout(1) where it exists (GNU coreutils); a perl alarm wrapper where it does not (macOS).
if command -v timeout >/dev/null 2>&1; then TMO=(timeout "$tmo")
else TMO=(perl -e 'alarm shift; exec @ARGV' "$tmo"); fi

# The PERL5LIB under which this perl loads the dist's dependencies, for the reference CLI and
# the module lists. The bundle runs this script with no PERL5LIB of its own and names where the
# dependencies are in DZIL_BINARY_PERL5LIB; unset or empty, this shell's PERL5LIB is used. The
# binary never sees either (env -i below).
deps=${DZIL_BINARY_PERL5LIB:-${PERL5LIB:-}}
with_deps() { PERL5LIB=$deps "$@"; }

# Both sides run in the same wiped environment, as the conformance runner builds it: a home of
# their own, git configured by the fixture's file alone, the fixture's CA for the url source.
envs=(PATH=/usr/bin:/bin HOME="$work/home" CODEX_HOME="$work/home/.codex" GIT_CONFIG_GLOBAL="$work/gitconfig"
      GIT_CONFIG_NOSYSTEM=1 LC_ALL=C SSL_CERT_FILE="$work/tls/ca.pem")
# The binary under a fresh extraction cache.
bin() { env -i "${envs[@]}" PAR_GLOBAL_TEMP="$cache" "${TMO[@]}" "$BIN" "$@" </dev/null; }
# The reference: the same CLI from the dist, its modules from the dependencies' PERL5LIB.
ref() { env -i "${envs[@]}" PERL5LIB="$deps" "${TMO[@]}" "$PERL" -I"$root/lib" "$root/script/skilletor" "$@" </dev/null; }

with_deps perl -I"$(native "$root/lib")" -MSkilletor -MText::Nunjucks -e1 2>"$work/deps.err" \
  || fail "the reference perl ($PERL) cannot load Skilletor and its dependencies" \
       "(DZIL_BINARY_PERL5LIB=${DZIL_BINARY_PERL5LIB:-<unset>}, PERL5LIB=${PERL5LIB:-<unset>}): $(head -n 1 "$work/deps.err")"
want_version=$(sed -n "s/^our \$VERSION = '\(.*\)';\$/\1/p" "$root/lib/Skilletor.pm")
[ -n "$want_version" ] || fail "cannot read \$VERSION from lib/Skilletor.pm"

# Packed module set. Inside the binary @INC is the archive only, so a module the build missed
# dies at run time, on a path this run may not reach. The full loaded set (scripts/loaded-modules.pl,
# the same list binary-pp-args.sh hands pp) must therefore be inside the archive itself.
# Archive::Zip comes with PAR::Packer.
with_deps perl -MArchive::Zip=:ERROR_CODES -e '
  my ( $bin, $dir ) = @ARGV;
  my $z = Archive::Zip->new($bin) or die "cannot read the PAR archive in $bin\n";
  for my $m ( grep { !$_->isDirectory } $z->members ) {
    $z->extractMember( $m, "$dir/".$m->fileName ) == AZ_OK or die "cannot unpack ".$m->fileName."\n";
  }' "$(native "$BIN")" "$(native "$work/archive")" 2>"$work/unzip.err" \
  || fail "cannot unpack the PAR archive: $(head -n 3 "$work/unzip.err")"
[ -d "$work/archive/lib" ] || fail "the PAR archive has no lib/"
(cd "$root" && with_deps perl -Ilib scripts/loaded-modules.pl) >"$work/loaded" 2>"$work/loaded.err" \
  || fail "scripts/loaded-modules.pl failed: $(cat "$work/loaded.err")"
tr -d '\r' <"$work/loaded" >"$work/loaded.lf" && mv "$work/loaded.lf" "$work/loaded"
nloaded=$(wc -l <"$work/loaded" | tr -d ' ')
[ "$nloaded" -gt 100 ] || fail "loaded set suspiciously small ($nloaded modules)"
missing=
# EXTRA_PACKED_CHECK="Not::Packed" adds names to the list (proves the check can fail).
for m in $(cat "$work/loaded") ${EXTRA_PACKED_CHECK:-}; do
  f="${m//:://}.pm"
  [ -f "$work/archive/lib/$f" ] || [ -f "$work/archive/arch/$f" ] || missing="$missing $f"
done
[ -z "$missing" ] || fail "modules missing inside the PAR archive:$missing (run verify where the binary was built)"
[ -s "$work/archive/lib/Mozilla/CA/cacert.pem" ] || fail "Mozilla/CA/cacert.pem is not packed (IO::Socket::SSL's fallback CA bundle)"
if [ -n "$windows" ]; then
  dll=$(find "$work/archive/lib/auto/Win32/Process" -name '*.dll' 2>/dev/null | head -n 1)
  [ -n "$dll" ] || fail "Win32::Process's shared object is not packed (the hooks' background sync)"
fi
echo "packed module set: OK ($nloaded modules, Mozilla::CA's bundle)"
# Left-out families: no member outside the loaded set inside the archive (the same list
# binary-pp-args.sh leaves out, read from scripts/left-out-modules.pl).
# shellcheck disable=SC2046  # one argument per module
famfiles=$(cd "$root" && with_deps perl -Ilib scripts/left-out-modules.pl --inc "$(native "$work/archive/lib")" -- $(cat "$work/loaded") | head -5)
[ -z "$famfiles" ] || fail "left-out families packed (${famfiles//$'\n'/ } ...); binary-pp-args.sh must leave them out"
echo "no left-out family packed: OK"

if [ -n "$windows" ]; then
  out=$("$BIN" --version </dev/null | tr -d '\r') || fail "--version failed"
  [ "$out" = "$want_version" ] || fail "--version prints '$out', want '$want_version'"
  echo "startup (--version): OK"
  echo "output equals perl -Ilib: skipped on Windows (POSIX-only; binary-smoke.sh runs every command there)"
  echo "verify: OK"
  exit 0
fi

# --- the fixture -------------------------------------------------------------------------
# pristine/ holds home and project before any run; every compared case starts both sides from
# a fresh copy at the same paths, so the outputs (paths included) must be equal byte for byte.
commit_env=(GIT_CONFIG_GLOBAL="$work/gitconfig" GIT_CONFIG_NOSYSTEM=1
            GIT_AUTHOR_NAME=verify GIT_AUTHOR_EMAIL=verify@skilletor.invalid
            GIT_COMMITTER_NAME=verify GIT_COMMITTER_EMAIL=verify@skilletor.invalid)
mkdir -p "$work/src/skills/plain/docs" "$work/src/skills/tpl" "$work/src/agents" "$work/src/rules" \
         "$work/git/remote/skills/remote-skill" "$work/web/top/skills/web-skill" "$work/tls" \
         "$work/pristine/home/.claude" "$work/pristine/project/.claude" "$work/cwd"
printf -- '---\nname: plain\ndescription: A plain skill\n---\nPlain.\n' > "$work/src/skills/plain/SKILL.md"
printf 'Reference.\n' > "$work/src/skills/plain/docs/ref.md"
printf -- '---\nname: tpl\ndescription: Greets {{ vars.who }}\n---\n{%% if vars.flag %%}Hello {{ vars.who | upper }} from {{ item.source }} ({{ harness }}, {{ scope }}).{%% endif %%}\n' \
  > "$work/src/skills/tpl/SKILL.md.njk"
printf -- '---\nname: rev\ndescription: Reviews\ntools: Read, Grep\n---\nReview.\n' > "$work/src/agents/rev.md"
printf -- '---\ndescription: Style\n---\nWrite clearly.\n' > "$work/src/rules/style.md"
printf '{ "vars": { "who": "world", "flag": true } }\n' > "$work/src/skilletor.json"
printf -- '---\nname: remote-skill\ndescription: From git\n---\nGit.\n' > "$work/git/remote/skills/remote-skill/SKILL.md"
printf -- '---\nname: web-skill\ndescription: From a url\n---\nWeb.\n' > "$work/web/top/skills/web-skill/SKILL.md"
printf '[url "file://%s"]\n\tinsteadOf = https://skilletor.invalid/remote.git\n' "$work/git/remote" > "$work/gitconfig"
# git before 2.32 has no GIT_CONFIG_GLOBAL and reads $HOME/.gitconfig instead: the same file
# there, for an older git in a build image.
cp "$work/gitconfig" "$work/pristine/home/.gitconfig"
for c in "init -q -b main" "add -A" "commit -q -m one"; do
  # shellcheck disable=SC2086  # $c is a fixed git argument list
  env "${commit_env[@]}" git -C "$work/git/remote" $c || fail "git $c in the fixture repository"
done
tar -C "$work/web" -czf "$work/web.tar.gz" top || fail "cannot make the url source's tarball"

# The url source: HTTPS on 127.0.0.1, a CA and a server certificate made here, an ETag so check
# can answer from a HEAD. Serves until killed; writes its port when it listens.
cat >"$work/server.pl" <<'EOF'
use strict; use warnings;
use IO::Socket::SSL; use IO::Socket::SSL::Utils qw( CERT_create PEM_cert2file PEM_key2file );
my ( $dir, $body_file ) = @ARGV;
my ( $ca, $cakey ) = CERT_create( CA => 1, subject => { CN => 'skilletor verify CA' } );
my ( $cert, $key ) = CERT_create( issuer => [ $ca, $cakey ], purpose => 'server',
  subject => { CN => '127.0.0.1' }, subjectAltNames => [ [ IP => '127.0.0.1' ] ] );
PEM_cert2file( $ca, "$dir/ca.pem" ); PEM_cert2file( $cert, "$dir/cert.pem" ); PEM_key2file( $key, "$dir/key.pem" );
my $srv = IO::Socket::SSL->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 10, ReuseAddr => 1,
  SSL_server => 1, SSL_cert_file => "$dir/cert.pem", SSL_key_file => "$dir/key.pem" ) or die "listen: $IO::Socket::SSL::SSL_ERROR";
open my $fh, '<:raw', $body_file or die $!; my $body = do { local $/; <$fh> }; close $fh;
open my $p, '>', "$dir/port.tmp" or die $!; print {$p} $srv->sockport; close $p; rename "$dir/port.tmp", "$dir/port" or die $!;
my $etag = '"verify-1"';
while (1) {
  my $c = $srv->accept or next;
  my ( $method, $inm ) = ( '', '' );
  while ( defined( my $l = <$c> ) ) {
    $method = $1 if !$method && $l =~ /\A(\w+) /;
    $inm = $1 if $l =~ /\AIf-None-Match:\s*(.*?)\s*\z/i;
    last if $l =~ /\A\r?\n\z/;
  }
  my $hit = $inm eq $etag;
  print {$c} 'HTTP/1.1 '.( $hit ? '304 Not Modified' : '200 OK' )."\r\nETag: $etag\r\nConnection: close\r\n"
    .( $hit ? "\r\n" : "Content-Type: application/gzip\r\nContent-Length: ".length($body)."\r\n\r\n" );
  print {$c} $body if !$hit && $method eq 'GET';
  close $c;
}
EOF
PERL5LIB=$deps "$PERL" "$work/server.pl" "$work/tls" "$work/web.tar.gz" 2>"$work/server.err" &
server=$!
for _ in $(seq 1 100); do [ -s "$work/tls/port" ] && break; sleep 0.1; done
[ -s "$work/tls/port" ] || fail "the fixture's HTTPS server did not start: $(cat "$work/server.err")"
port=$(cat "$work/tls/port")

printf '{}\n' > "$work/pristine/home/.claude.json"
cat > "$work/pristine/home/.claude/skilletor.json" <<EOF
{
  "sources": {
    "loc": { "local": "$work/src" },
    "remote": { "git": "https://skilletor.invalid/remote.git" },
    "web": { "url": "https://127.0.0.1:$port/skills.tar.gz" }
  },
  "install": {
    "skills": ["*@loc", "remote-skill@remote", "web-skill@web"],
    "agents": ["rev@loc"],
    "rules": ["style@loc"]
  }
}
EOF
cat > "$work/pristine/project/.claude/skilletor.json" <<EOF
{
  "sources": { "proj": { "local": "$work/src" } },
  "install": { "skills": ["plain@proj"] }
}
EOF

# fresh: home and project as in pristine/, every earlier run's lock, state and files gone.
fresh() { rm -rf "${work:?}/home" "${work:?}/project"; cp -R "$work/pristine/home" "$work/pristine/project" "$work/"; }
# The installed files of home and project, skilletor's state dir left out (it holds times).
tree_of() { ( cd "$work" && find home project -path home/.claude/skilletor -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done ); }

# same_as_perl CASE ARGS...: stdout, stderr, exit code and the files written are those of the
# checkout's perl run, each side from a fresh fixture in the project directory. SETUP="ARGS"
# runs one command first on each side (its output is not compared), so a case can follow a sync.
# The reference must have printed something (EXPECT_EMPTY=1 for a case that prints nothing).
same_as_perl() {
  local name=$1; shift
  local side rc
  for side in want got; do
    fresh
    rc=0
    # shellcheck disable=SC2086  # SETUP is an argument list
    if [ -n "${SETUP:-}" ]; then
      if [ "$side" = want ]; then (cd "$work/project" && ref $SETUP) >/dev/null 2>&1 || true
      else (cd "$work/project" && bin $SETUP) >/dev/null 2>&1 || true; fi
    fi
    if [ "$side" = want ]; then (cd "$work/project" && ref "$@") >"$work/$side.out" 2>"$work/$side.err" || rc=$?
    else (cd "$work/project" && bin "$@") >"$work/$side.out" 2>"$work/$side.err" || rc=$?; fi
    echo "$rc" > "$work/$side.rc"
    tree_of > "$work/$side.tree"
  done
  [ "$(cat "$work/want.rc")" = "$(cat "$work/got.rc")" ] \
    || fail "$name: exit code differs (binary $(cat "$work/got.rc"), perl $(cat "$work/want.rc")): $(head -c 400 "$work/got.err")"
  if [ -z "${EXPECT_EMPTY:-}" ]; then
    [ -s "$work/want.out" ] || [ -s "$work/want.err" ] || fail "$name: the perl reference printed nothing, the case proves nothing"
  fi
  cmp -s "$work/want.out" "$work/got.out" || fail "$name: stdout differs from perl -Ilib (binary: $(wc -c <"$work/got.out") bytes, perl: $(wc -c <"$work/want.out") bytes)"
  cmp -s "$work/want.err" "$work/got.err" || fail "$name: stderr differs from perl -Ilib: binary '$(head -c 400 "$work/got.err")', perl '$(head -c 400 "$work/want.err")'"
  cmp -s "$work/want.tree" "$work/got.tree" || fail "$name: the files written differ from perl -Ilib"
}

cd "$work/cwd"
# Startup on a fresh cache (the extraction run), then a second start on the same cache.
out=$(bin --version) || fail "--version failed on a fresh cache"
[ "$out" = "$want_version" ] || fail "--version prints '$out', want '$want_version'"
echo "startup (--version, fresh cache): OK"
out=$(bin --version) || fail "--version failed on the second start"
[ "$out" = "$want_version" ] || fail "second start prints '$out'"
echo "second start (same cache): OK"

same_as_perl "--help" --help
same_as_perl "no command"
same_as_perl "sync --help" sync --help
same_as_perl "-v" -v
same_as_perl "unknown command (exit 2)" nope
same_as_perl "unknown option (exit 2)" --nope
same_as_perl "sync --bogus (exit 2)" sync --bogus
same_as_perl "sync --scope nope (exit 2)" sync --scope nope
same_as_perl "add without a spec (exit 2)" add
echo "help and usage: OK"

same_as_perl "status before a sync" status
same_as_perl "sync: local, git and https url sources" sync
same_as_perl "sync --json" sync --json
same_as_perl "sync --scope user" sync --scope user
SETUP=sync same_as_perl "sync after a sync" sync
SETUP=sync same_as_perl "check after a sync (HEAD to the url source)" check
SETUP=sync same_as_perl "check --json after a sync" check --json
SETUP=sync same_as_perl "status after a sync" status
SETUP=sync same_as_perl "status --json after a sync" status --json
same_as_perl "check before a sync (exit 1)" check
echo "sync, check, status: OK"

# The url source's round trip really happened: its skill is installed.
fresh; (cd "$work/project" && bin sync) >/dev/null 2>&1 || fail "sync failed"
[ -f "$work/home/.claude/skills/web-skill/SKILL.md" ] || fail "sync installed no skills/web-skill from the https url source"
[ -f "$work/home/.claude/skills/remote-skill/SKILL.md" ] || fail "sync installed no skills/remote-skill from the git source"
grep -q 'Hello WORLD from loc' "$work/home/.claude/skills/tpl/SKILL.md" || fail "sync rendered no skills/tpl from its template"
echo "backends (local + template, git, https url): OK"

# Error paths: a config that does not parse, a source the config does not declare, the url
# source down (cached copy: a warning; none: a failure).
printf '{ "sources": ' > "$work/pristine/home/.claude/skilletor.json.broken"
mv "$work/pristine/home/.claude/skilletor.json" "$work/pristine/home/.claude/skilletor.json.good"
cp "$work/pristine/home/.claude/skilletor.json.broken" "$work/pristine/home/.claude/skilletor.json"
same_as_perl "sync with a broken config (exit 2)" sync
same_as_perl "check with a broken config (exit 2)" check
same_as_perl "status with a broken config (exit 2)" status
mv "$work/pristine/home/.claude/skilletor.json.good" "$work/pristine/home/.claude/skilletor.json"
rm -f "$work/pristine/home/.claude/skilletor.json.broken"
kill "$server" 2>/dev/null || true; wait "$server" 2>/dev/null || true; server=
same_as_perl "sync with the url source down" sync
echo "error paths: OK"
echo "output equals perl -Ilib: OK"
echo "verify: OK"
