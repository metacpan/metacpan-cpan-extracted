#!/usr/bin/env bash
# Run the test suite against the minimum Kubernetes::REST and IO::K8s the
# cpanfile pins, from a local::lib of their own.
#
# The installed Kubernetes::REST and IO::K8s are usually ahead of the pins,
# and a -I overlay of an older release's lib/ still finds every module that
# release does not ship in the site lib - Kubernetes/REST/APIError.pm next
# to 1.108's Kubernetes/REST.pm. This script creates, or reuses, a
# self-contained local::lib (cpanm -L) holding exactly the pinned releases
# plus the rest of the cpanfile, test phase included (dependencies are
# installed with --notest), and runs prove against it with the
# environment's local::lib (PERL5LIB, PERL_LOCAL_LIB_ROOT, ...) removed:
# perl searches that directory, then only its own compiled-in ones. Before
# the tests it prints which Kubernetes::REST and IO::K8s load, and refuses
# to run when either is not the pinned version, not loaded from that
# directory, or also present in another @INC directory. Mock mode only:
# TEST_KUBERNETES_REST_KUBECONFIG is unset.
#
# Usage:
#   maint/prove-pinned.sh [--lib DIR] [--setup] [--setup-only] [-- PROVE_ARGS]
#
#   --lib DIR      the local::lib to create or reuse (default:
#                  ${TMPDIR:-/tmp}/nak-pinned-REST-<pin>-IOK8s-<pin>)
#   --setup        run cpanm even though DIR was set up for this cpanfile
#   --setup-only   set up and report the versions, run no tests
#   PROVE_ARGS     what prove runs (default: -lr t/)
#
# Environment: PERL (default: perl on PATH), CPANM (default: cpanm on PATH).
# cpanm needs network access the first time, and after any cpanfile change.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

lib=
setup=0
setup_only=0
while [ $# -gt 0 ]; do
  case $1 in
    --lib)        lib=${2:?--lib needs a directory}; shift 2 ;;
    --lib=*)      lib=${1#--lib=}; shift ;;
    --setup)      setup=1; shift ;;
    --setup-only) setup_only=1; shift ;;
    --)           shift; break ;;
    -h|--help)    sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *)            echo "prove-pinned: unknown option '$1' (see --help)" >&2; exit 2 ;;
  esac
done
[ $# -gt 0 ] || set -- -lr t/

# The minimum version the cpanfile requires for module $1.
pin() {
  local version
  version=$(sed -n "s/^requires '$1', *'\([^']*\)';.*/\1/p" cpanfile)
  if [ -z "$version" ]; then
    echo "prove-pinned: cpanfile pins no version of $1" >&2
    exit 2
  fi
  printf '%s\n' "$version"
}
rest_pin=$(pin 'Kubernetes::REST')
k8s_pin=$(pin 'IO::K8s')

# Nothing from the environment's own local::lib or perl switches, and never
# a live cluster.
unset PERL5LIB PERLLIB PERL5OPT PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT \
  PERL_CPANM_OPT HARNESS_PERL_SWITCHES TEST_KUBERNETES_REST_KUBECONFIG

perl=${PERL:-$(command -v perl)}
cpanm=${CPANM:-$(command -v cpanm || true)}

lib=${lib:-${TMPDIR:-/tmp}/nak-pinned-REST-$rest_pin-IOK8s-$k8s_pin}
mkdir -p "$lib"
lib=$(cd "$lib" && pwd)
stamp=$lib/.prove-pinned.cpanfile

if [ "$setup" = 1 ] || ! cmp -s cpanfile "$stamp"; then
  if [ -z "$cpanm" ]; then
    echo "prove-pinned: no cpanm on PATH (set CPANM)" >&2
    exit 2
  fi
  # IO::K8s first: Kubernetes::REST requires it, and cpanm would satisfy that
  # with the newest release. The rest of the cpanfile finds both pins
  # installed.
  "$perl" "$cpanm" -L "$lib" --notest "IO::K8s@$k8s_pin"
  "$perl" "$cpanm" -L "$lib" --notest "Kubernetes::REST@$rest_pin"
  "$perl" "$cpanm" -L "$lib" --notest --installdeps .
  cp cpanfile "$stamp"
fi

export PERL5LIB=$lib/lib/perl5

"$perl" -Mstrict -Mwarnings -Mversion -e '
  my ($lib, %pin) = @ARGV;
  my @elsewhere;
  for my $dir (grep { !ref && index($_, $lib) != 0 } @INC) {
    push @elsewhere, grep { -e } map { ("$dir/$_", "$dir/$_.pm") } qw( Kubernetes/REST IO/K8s );
  }
  die "prove-pinned: outside $lib, \@INC also has: @elsewhere\n" if @elsewhere;
  for my $module (sort keys %pin) {
    (my $file = "$module.pm") =~ s{::}{/}g;
    eval "require $module; 1" or die "prove-pinned: $module does not load: $@";
    my $version = $module->VERSION;
    print "prove-pinned: $module $version from $INC{$file}\n";
    die "prove-pinned: the cpanfile pins $module $pin{$module} - rerun with --setup\n"
      unless version->parse($version) == version->parse($pin{$module});
    die "prove-pinned: $module is not loaded from $lib\n" unless index($INC{$file}, $lib) == 0;
  }
' "$lib" 'Kubernetes::REST' "$rest_pin" 'IO::K8s' "$k8s_pin"

[ "$setup_only" = 0 ] || exit 0

exec "$perl" -MApp::Prove -e '
  my $app = App::Prove->new;
  $app->process_args(@ARGV);
  exit($app->run ? 0 : 1);
' -- "$@"
