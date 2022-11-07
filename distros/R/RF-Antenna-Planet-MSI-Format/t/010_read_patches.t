use strict;
use warnings;
use Test::More tests => 11;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

sub j {join "", map {$_."\n"} @_};

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  my $file = j(
               "NAME required",
               "HORIZONTAL 180 0", #in several files
               (map {" \t ". 2*$_ . " \t 0.1   \t"} (0 .. 179)),
               "VERTICAL", #in several files
               (map {"$_ 0.1"} (0 .. 359)),
              );
  $antenna->read(\$file);
  is($antenna->name, 'required', 'name');

  isa_ok($antenna->horizontal, 'ARRAY');
  is(scalar(@{$antenna->horizontal}), 180, 'sizeof horizontal');
  is($antenna->horizontal->[0]->[0], 0, '$antenna->horizontal->[0]->[0]');
  is($antenna->horizontal->[-1]->[0], 2*179, '$antenna->horizontal->[-1]->[0]');

  isa_ok($antenna->vertical, 'ARRAY');
  is(scalar(@{$antenna->vertical}), 360, 'sizeof vertical');
  is($antenna->vertical->[0]->[0], 0, '$antenna->vertical->[0]->[0]');
  is($antenna->vertical->[359]->[0], 359, '$antenna->vertical->[359]->[0]');
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  my $file = j(
               "required", #name without key
               "",         #trailing lines
               "",         #trailing lines
               "\t",       #trailing lines
               " ",        #trailing lines
               " \t ",     #trailing lines
               "",         #trailing lines
               "",         #trailing lines
               "",         #trailing lines
              );
  $antenna->read(\$file);
  is($antenna->name, 'required', 'name');
}
