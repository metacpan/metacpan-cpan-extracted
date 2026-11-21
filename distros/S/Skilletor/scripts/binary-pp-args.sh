#!/usr/bin/env bash
# The pp arguments of the skilletor binary, one per line on STDOUT: binary_pp_args of the
# [@Author::GETTY] bundle (dist.ini). Run from the dist root with the perl that packs; problems
# go to STDERR and end the run with exit 1, which fails the build.
#   scripts/binary-pp-args.sh
#
# The bundle runs pp itself -- locally after `dzil build`, and per platform in its dzil-binary
# workflow -- as  PAR_VERBATIM=1 pp -o OUT -I lib <these lines> script/skilletor. This script
# adds what pp cannot know: the -M set and the -X set.
#
# The sets run to some 2000 options, past the 32767 characters of a Windows command line. So
# they go into binary-pp-args.txt in the dist root, and the one line printed is
# @binary-pp-args.txt: pp reads an @FILE argument as options (Getopt::ArgvFile), every platform
# alike. The file stays for every pp run of the pack (Windows packs twice), and the next run of
# this script overwrites it; Dist::Zilla archives its own file list, not the build dir.
#
# pp exits 0 on a binary that only dies at run time; scripts/binary-verify.sh and
# scripts/binary-smoke.sh are what prove a build.
set -euo pipefail

[ -f script/skilletor ] && [ -f lib/Skilletor.pm ] || { echo "ERROR: run from the dist root" >&2; exit 1; }

# Every module needed at run time must be installed, or the loaded set below is short.
perl -Ilib -MSkilletor -MText::Nunjucks -e1 \
  || { echo "ERROR: runtime dependencies missing (cpanm --installdeps .)" >&2; exit 1; }
# TLS: IO::Socket::SSL on Net::SSLeay, and Mozilla::CA as the trust store of last resort.
# Net::SSLeay carries whatever OpenSSL it was built against into the binary: a portable build
# links OpenSSL statically (scripts/binary-prepare.sh, binary_prepare), a dev-box build links the
# host's libssl, which the bundle's library gate rejects.
perl -MIO::Socket::SSL=2.009 -MMozilla::CA -e1 \
  || { echo "ERROR: TLS modules missing (scripts/binary-prepare.sh, or cpanm IO::Socket::SSL Mozilla::CA)" >&2; exit 1; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# The loaded set: scripts/loaded-modules.pl runs every command and hook on a fixture and prints
# every module that came from its own file, the ones loaded by name included (the Error classes,
# the Source backends, Text::Nunjucks' node classes, IO::Socket::SSL, Net::SSLeay, Mozilla::CA,
# Win32::Process on Windows). binary-verify.sh requires the same list inside the archive.
perl -Ilib scripts/loaded-modules.pl >"$work/loaded" \
  || { echo "ERROR: scripts/loaded-modules.pl failed" >&2; exit 1; }
loaded=(); while IFS= read -r m; do m=${m%$'\r'}; [ -n "$m" ] && loaded+=("$m"); done <"$work/loaded"
[ "${#loaded[@]}" -gt 100 ] || { echo "ERROR: loaded set suspiciously small (${#loaded[@]})" >&2; exit 1; }

# Left out of every build (the families and why: scripts/left-out-modules.pl), less the loaded
# set: each member found in @INC on this host, one -X each. binary-verify.sh rejects any of them
# in the archive.
perl -Ilib scripts/left-out-modules.pl -- "${loaded[@]}" >"$work/left-out" \
  || { echo "ERROR: scripts/left-out-modules.pl failed" >&2; exit 1; }
noopt=(); while IFS= read -r m; do m=${m%$'\r'}; [ -n "$m" ] && noopt+=("$m"); done <"$work/left-out"

# The option file, read as pp reads it: each line split into words like a shell's, $NAME and
# ${NAME} replaced from the environment, quotes and backslashes taken out, a word starting with
# @ read as a file in turn. A module name or code path holds none of these; a name that does
# stops the build here instead of packing a different set.
for m in "${loaded[@]}" ${noopt[@]+"${noopt[@]}"}; do
  [[ $m =~ ^[[:alnum:]_][[:alnum:]_:./-]*$ ]] \
    || { echo "ERROR: '$m' cannot go into pp's option file (scripts/loaded-modules.pl, scripts/left-out-modules.pl)" >&2; exit 1; }
done
list=binary-pp-args.txt
{
  for m in "${loaded[@]}"; do printf -- '-M %s\n' "$m"; done
  for m in ${noopt[@]+"${noopt[@]}"}; do printf -- '-X %s\n' "$m"; done
} >"$list"

# One argument per line, never word-split (the bundle's rule for binary_pp_args). The file by
# its bare name: the bundle runs pp in the dist root this script runs in (the workflow's
# `-I lib ... script/skilletor` are relative to it), and Git Bash hands a name without / or :
# to a native perl unconverted.
printf '@%s\n' "$list"

echo "binary-pp-args: ${#loaded[@]} modules (-M), ${#noopt[@]} left out (-X) in $list;" \
  "$(perl -MNet::SSLeay -e 'print Net::SSLeay::SSLeay_version(0)')" >&2
