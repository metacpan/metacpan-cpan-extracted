use 5.006;
use strict;
use warnings;

use Config;
use Cwd 'abs_path';
use File::Spec;
use IPC::Run3;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename()

# }}}1
# --- Attempts to create two candidates with the same arity ------------
# Two candidates with the same arity and no other distinguishing
# features die when the dispatcher is made.

# We have to run the test in a separate Perl process so we can see
# errors at INIT time
my $perl = get_perl_filename or die "Could not find perl interpreter";

# Find the .pl file

# Find the dist's root
my $here = abs_path(__FILE__);
die "Could not find my file location: $!" unless defined $here;
my ($volume,$directories,undef) = File::Spec->splitpath( $here );

# Find t/32_same_arity.t
my $pl_file = File::Spec->catpath(
    $volume,
    $directories,
    '32_same_arity.pl'
);
die "Could not read $pl_file" unless -f $pl_file && -r _;

my ($in, $out, $err, $exitstatus);
my @cmd = ($perl, (map { "-I$_" } @INC), $pl_file);
diag 'Running ', join ' ', @cmd;
run3 \@cmd, \$in, \$out, \$err;     # Dies on error
$exitstatus = $?;
diag "Error message was '$err'" if $err;

cmp_ok $exitstatus>>8, '!=', 0, "returned a failure indication";
like $err, qr/distinguish.*arity/,
    "detected two same-arity candidates";

done_testing;

# vi: set fdm=marker: #
