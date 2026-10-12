#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Every module is checked at 100%, and the list is read from the tree so a
# module added later cannot escape by not being named here.
my @MODULES;
for my $path (glob 'lib/Term/Chess.pm lib/Term/Chess/*.pm') {
    my $m = $path;
    $m =~ s{\Alib/}{}; $m =~ s{\.pm\z}{}; $m =~ s{/}{::}g;
    push @MODULES, $m;
}

# THE NAMES OBJECT::PROTO INSTALLS ARE EXEMPT, and nothing else is. Every
# attribute declared with `has` is ours and is checked.
my $GENERATED = qr/\A(?:new|prototype|set_prototype|BUILD|DEMOLISH)\z/;

plan tests => scalar @MODULES;
for my $module (sort @MODULES) {
    pod_coverage_ok($module, { also_private => [$GENERATED] },
                    "$module documents every method it offers");
}
