use strict;
use warnings;
use Test::More tests => 3;
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

  is($antenna->blob, $file, 'blob');
}
