use 5.006;
use lib::relative '.';
use Kit;

# Skip rather than falsely fail - see https://github.com/rjbs/IPC-Run3/pull/9
# and RT#95308.  Example at
# http://www.cpantesters.org/cpan/report/277b2ad8-6bf8-1014-b7dc-c8197f9146ad
plan skip_all => 'MSWin32 gives a false failure on this test'
    if $^O eq 'MSWin32';

plan tests => 2;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

# --- Attempts to create two candidates with the same arity ------------
# Two candidates with the same arity and no other distinguishing
# features die when the dispatcher is made.

# Find the Perl file to run
my $pl_file = find_file_in_t('32_same_arity.pl', 'r');
my ($out, $err, $exitstatus) = run_perl([$pl_file]);

cmp_ok $exitstatus>>8, '!=', 0, "returned a failure indication";
like $err, qr/distinguish.*arity/,
    "detected two same-arity candidates";

# vi: set fdm=marker: #
