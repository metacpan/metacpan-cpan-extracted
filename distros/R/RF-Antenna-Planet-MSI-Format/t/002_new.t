use strict;
use warnings;
use Test::More tests => 13;
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>[NAME => "My Name", MAKE => "My Make"]);
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name ARRAY');
  is($antenna->make, "My Make", 'make ARRAY');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>{NAME => "My Name", MAKE => "My Make"});
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name HASH');
  is($antenna->make, "My Make", 'make HASH');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(NAME => "My Name", MAKE => "My Make");
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name keys');
  is($antenna->make, "My Make", 'make keys');
}
