use strict;
use warnings;
use Test::More tests => 4*6 + 7 + 1;
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>[name => "My Name", make => "My Make"]);
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name lc ARRAY');
  is($antenna->make, "My Make", 'make lc ARRAY');


  my $file = $antenna->write;
  my @lines = $file->slurp(chomp => 1);
  is(scalar(@lines), 2, 'lines');
  is($lines[0], "NAME My Name", 'name');
  is($lines[1], "MAKE My Make", 'make');
  $file->remove;

  is($antenna->name("New Name"), "New Name", 'name set');
  is($antenna->name, "New Name", 'name set');
  is($antenna->make("New Make"), "New Make", 'make set');
  is($antenna->make, "New Make", 'make set');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>[NAME => "My Name", MAKE => "My Make"]);
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name uc ARRAY');
  is($antenna->make, "My Make", 'make uc ARRAY');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>{name => "My Name", make => "My Make"});
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name lc HASH');
  is($antenna->make, "My Make", 'make lc HASH');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(header=>{NAME => "My Name", MAKE => "My Make"});
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name uc HASH');
  is($antenna->make, "My Make", 'make uc HASH');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(name => "My Name", make => "My Make");
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name lc keys');
  is($antenna->make, "My Make", 'make lc keys');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new(NAME => "My Name", MAKE => "My Make");
  isa_ok($antenna->header, 'HASH');
  ok(tied %{$antenna->header}, 'tied');
  is($antenna->name, "My Name", 'name uc keys');
  is($antenna->make, "My Make", 'make us keys');
}
