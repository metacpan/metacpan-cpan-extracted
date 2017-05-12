# -*- perl -*-

use Test::More tests => 1;
SKIP: {
  eval "use Test::YAML::Meta::Version; use YAML::Syck qw(LoadFile)";
  skip "Test::YAML::Meta::Version and YAML::Syck required for testing META.yml", 1 if $@;

my %data = (
  yaml => LoadFile("META.yml"),
);

my $spec = Test::YAML::Meta::Version->new(%data);

ok (!$spec->parse());

#warn join("\n",$spec->errors);
}
