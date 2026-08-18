use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9070-examples.t - the eg/ examples stay real and stay documented:
#   X1  the example is listed in MANIFEST
#   X2  it compiles under "perl -Ilib -c"
#   X3  the POD of lib/TUI/Handy.pm names it under =head1 EXAMPLES
#   X4  README names it under EXAMPLES
#   X5  every eg/*.pl the POD names actually exists on disk
#
# INA_CPAN_Check check_F (called from t/9000-ina-cpan-check.t) asserts only
# that at least one eg/*.pl is shipped.  This file does not repeat that
# assertion; it checks what happens to each example once it exists, which is
# where examples actually rot: a script that no longer compiles against the
# current module, or one that was added or renamed without the two documents
# that advertise it following along.

use lib 't/lib';
use INA_CPAN_Check;

# Directory separators are normalised to '/' so the MANIFEST comparison
# holds on Windows too.
sub eg_scripts {
    my @found;
    local *D;
    return () unless -d 'eg';
    opendir(D, 'eg') or return ();
    my @e = sort grep { /\.pl$/ } readdir(D);
    closedir(D);
    for my $e (@e) {
        push @found, "eg/$e";
    }
    return @found;
}

# Compile the script in a child perl with STDERR discarded, so a clean run
# says nothing and only the exit status matters.  A piped two-argument open
# is portable to Perl 5.005_03 on both cmd.exe and sh.
sub compiles {
    my ($file) = @_;
    require File::Spec;
    my $devnull = File::Spec->devnull();
    my $perl = $^X;
    $perl = qq{"$perl"} if $perl =~ /\s/;
    my $rc = system("$perl -Ilib -c $file > $devnull 2> $devnull");
    return ($rc == 0) ? 1 : 0;
}

my @scripts = eg_scripts();

my %in_manifest;
for my $f (_manifest_files('.')) {
    $in_manifest{$f} = 1;
}

# The =head1 EXAMPLES section of the module POD, and the EXAMPLES section of
# the README, as plain text.
my $pod = _slurp('lib/TUI/Handy.pm');
my $pod_examples = ($pod =~ /^=head1[ \t]+EXAMPLES\b(.*?)^=head1/ms) ? $1 : '';

my $readme = _slurp('README');
my $readme_examples = ($readme =~ /^EXAMPLES\b(.*?)^\S/ms) ? $1 : '';

my @tests;

for my $script (@scripts) {
    my $f = $script;
    push @tests, sub { ok($in_manifest{$f}, "X1 - $f is listed in MANIFEST") };
    push @tests, sub { ok(compiles($f), "X2 - $f compiles") };
    push @tests, sub {
        ok((index($pod_examples, $f) >= 0) ? 1 : 0,
           "X3 - POD =head1 EXAMPLES names $f");
    };
    push @tests, sub {
        ok((index($readme_examples, $f) >= 0) ? 1 : 0,
           "X4 - README EXAMPLES names $f");
    };
}

# Reverse direction: nothing is advertised that is not there.
push @tests, sub {
    my @named = $pod_examples =~ m{(eg/[\w.-]+\.pl)}g;
    my @missing = ();
    for my $n (@named) {
        push @missing, $n unless -f $n;
    }
    ok(!@missing, 'X5 - every eg/*.pl named in the POD exists'
                . (@missing ? " (@missing)" : ''));
};

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
