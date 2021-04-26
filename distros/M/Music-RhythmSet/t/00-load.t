#!perl
use 5.24.0;
use Test2::V0;

# TODO better way to bail out should the modules not load?
# Test2::Bundle::More claims "These are not necessary" for "use_ok"
# and friends
my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Music::RhythmSet::Voice
Music::RhythmSet::Util
Music::RhythmSet
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Music::RhythmSet $Music::RhythmSet::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );
done_testing;
