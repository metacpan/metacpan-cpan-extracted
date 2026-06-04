use utf8;
use Test2::V0;
use Test::Needs 'Types::Serialiser';
use TOML::Tiny;

# With Types::Serialiser installed, TOML booleans inflate to boolean
# objects and round-trip faithfully back to "true"/"false". Without it,
# they inflate to 1/0 and cannot round-trip (documented behaviour), so
# this coverage lives in its own Test::Needs-guarded file. See GH #46.

my $coder = TOML::Tiny->new(no_string_guessing => 1);

my $input = "boolf=false\nboolt=true\n";
my $output = join "\n", sort grep /./, split /\n/, $coder->encode($coder->decode($input));

is($output, "boolf=false\nboolt=true", 'booleans round-trip faithfully');

done_testing;
