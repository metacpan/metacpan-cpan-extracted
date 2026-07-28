#!/perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author/Release tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;

my @modules = all_modules('lib');
my @tested;
for my $module (@modules) {
    eval "require $module;";
    my $pc = Pod::Coverage->new(package => $module);
    if (!defined $pc || !defined $pc->coverage || ($pc->why_unrated && $pc->why_unrated =~ /couldn't find pod/i)) {
        note("Skipping POD coverage for $module (no POD present)");
        next;
    }
    pod_coverage_ok($module, { also_private => [ 'Changes_guts', 'README_guts', 'README_md_guts', qr!^[a-z_]! ] });
    push @tested, $module;
}

if (!@tested) {
    plan skip_all => "No modules with POD documentation found in distribution";
} else {
    done_testing();
}
