use Speech::Synthesis;
use Test::More;
use strict;
use warnings;

my @engines = Speech::Synthesis->InstalledEngines();
@engines = grep {$_ eq 'MSAgent'} @engines;
plan skip_all => "No Speech Engines installed that support Avatars" unless @engines;
plan tests => scalar(@engines);

foreach my $engine (@engines)
{
    my @avatars = Speech::Synthesis->InstalledAvatars(engine => $engine);
SKIP:{    skip "No avatars installed for engine $engine", 1 unless @avatars;
    ok(scalar(@avatars) > 0, "You have installed the following avatars for engine $engine: ".join(", ", @avatars));
};
}