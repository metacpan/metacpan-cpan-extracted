use Speech::Synthesis;
use Test::More;
use strict;
use warnings;

my @engines = Speech::Synthesis->InstalledEngines();
plan skip_all => "No Speech Engines installed" unless @engines;
plan tests => scalar(@engines);

foreach my $engine (@engines)
{
    my @langs = Speech::Synthesis->InstalledLanguages(engine => $engine,
                                                        host   => $ENV{FESTIVAL_HOST},
                                                        port   => $ENV{FESTIVAL_PORT});
SKIP:{
        skip "No languages installed for engine $engine", 1 unless @langs;
        ok(scalar(@langs) > 0, "You have installed languages ".join(", ", @langs)." for engine $engine");
     };
}