#!/bin/sh
# check Docker base image for any missing components, fail if any
set -eu

# allow opt-out, either build with `--build-arg VERIFY_BASE=0` or set "VERIFY_BASE" env var at build time
: "${VERIFY_BASE:=1}"
[ "$VERIFY_BASE" = "1" ] || {
  echo "verify-base: skipped (VERIFY_BASE=$VERIFY_BASE)"; exit 0; }

echo "verify-base: starting checks..."

# load environmental variables "IO_LINUX_PERL_*"
. /usr/local/share/linux_perl_base.env

# verification check #1: metadata env vars, set by Docker base image
: "${IO_LINUX_PERL_BASE:=}" \
  "${IO_LINUX_PERL_PERL_VERSION:=}" \
  "${IO_LINUX_PERL_PERL_ARCHNAME:=}"

[ "$IO_LINUX_PERL_BASE" = "1" ] || {
  echo "verify-base: missing IO_LINUX_PERL_BASE=1 marker (not a prepared base)"; exit 1; }

[ -n "$IO_LINUX_PERL_PERL_VERSION" ] || {
  echo "verify-base: missing IO_LINUX_PERL_PERL_VERSION"; exit 1; }

[ -n "$IO_LINUX_PERL_PERL_ARCHNAME" ] || {
  echo "verify-base: missing IO_LINUX_PERL_PERL_ARCHNAME"; exit 1; }

# verification check #2: toolchain presence, these should be available in the Docker base image
command -v gcc    >/dev/null 2>&1 || { echo "verify-base: gcc not found"; exit 1; }
command -v make   >/dev/null 2>&1 || { echo "verify-base: make not found"; exit 1; }
command -v git    >/dev/null 2>&1 || { echo "verify-base: git not found"; exit 1; }
command -v cpanm  >/dev/null 2>&1 || { echo "verify-base: cpanm not found"; exit 1; }
command -v dzil   >/dev/null 2>&1 || { echo "verify-base: dzil not found"; exit 1; }

# verification check #3: runtime Perl must be usable; optionally enforce Perl version & architecture match
perl -MConfig -e 'print "$Config{version} $Config{archname}\n"' >/tmp/_perl.verarch 2>/dev/null \
  || { echo "verify-base: perl runtime not usable"; exit 1; }
runtime_ver="$(cut -d' ' -f1 </tmp/_perl.verarch)"
runtime_arch="$(cut -d' ' -f2 </tmp/_perl.verarch)"

# default to true "1" if env var "STRICT_PERL_MATCH" is not set
if [ "${STRICT_PERL_MATCH:-1}" = "1" ]; then
  [ "$runtime_ver"  = "$IO_LINUX_PERL_PERL_VERSION" ]  || {
    echo "verify-base: perl version mismatch: runtime=$runtime_ver label=$IO_LINUX_PERL_PERL_VERSION"; exit 1; }
  [ "$runtime_arch" = "$IO_LINUX_PERL_PERL_ARCHNAME" ] || {
    echo "verify-base: perl arch mismatch: runtime=$runtime_arch label=$IO_LINUX_PERL_PERL_ARCHNAME"; exit 1; }
fi

echo "verify-base: OK (Perl $runtime_ver $runtime_arch)"
