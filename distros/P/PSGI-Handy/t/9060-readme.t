######################################################################
# 9060-readme.t  README structure and content checks.
#
# Checks:
#   R1  Required sections present
#   R2  No non-existent method names cited (distribution-specific list)
#   R3  Every shipped eg/NN_*.pl example is listed in README
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_skip('README not found') unless -f "$ROOT/README";

# Required README sections (common to all ina@CPAN distributions)
my @required_sections = qw(
    NAME SYNOPSIS DESCRIPTION
    INSTALLATION COMPATIBILITY
    AUTHOR
);
# Optional but expected sections in PSGI-Handy
my @recommended_sections = (
    'INCLUDED DOCUMENTATION',
    'TARGET USE CASES',
    'LIMITATIONS',
    'COPYRIGHT AND LICENSE',
);

# Methods/names that must NOT appear (non-existent API)
my @phantom_names = ();

# R3 - every shipped example program must be documented in README.
# Discover eg/NN_*.pl on disk (opendir/readdir keeps this 5.005_03 safe).
my @eg_files;
{
    my $egdir = File::Spec->catdir($ROOT, 'eg');
    if (-d $egdir) {
        local *EGDIR;
        if (opendir(EGDIR, $egdir)) {
            my $entry;
            while (defined($entry = readdir(EGDIR))) {
                push @eg_files, $entry if $entry =~ /^\d+_.*\.pl$/;
            }
            closedir(EGDIR);
        }
    }
    @eg_files = sort @eg_files;
}

my $total = scalar(@required_sections)
          + scalar(@recommended_sections)
          + 1                        # R2 phantom check
          + scalar(@eg_files);       # R3 one per example
plan_tests($total);

my $text = _slurp("$ROOT/README");

my $sec;
for $sec (@required_sections) {
    ok(index($text, $sec) >= 0,
       "R1 - README required section present: $sec");
}

for $sec (@recommended_sections) {
    ok(index($text, $sec) >= 0,
       "R1 - README recommended section present: $sec");
}

my @found_phantom;
my $name;
for $name (@phantom_names) {
    push @found_phantom, $name if index($text, $name) >= 0;
}
ok(!@found_phantom,
   'R2 - README contains no phantom API names'
   . (@found_phantom ? " (found: @found_phantom)" : ''));

my $eg;
for $eg (@eg_files) {
    ok(index($text, "eg/$eg") >= 0,
       "R3 - README lists example: eg/$eg");
}

END { end_testing() }
