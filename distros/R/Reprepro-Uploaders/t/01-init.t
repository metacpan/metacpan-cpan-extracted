use warnings;
use strict;
use Test::More tests => 1;
use Reprepro::Uploaders;

my $uploaders = Reprepro::Uploaders->new(
   uploaders   => "/etc/reprepro/uploaders",  # Mandatory, no default
   verbose     => 1,                          # Or debug for more messages
   augeas_opts => {                           # Setup Config::Augeas
      root     => "fakeroot",
      loadpath => "lenses",
   },
);
ok($uploaders, "Created new Reprepro::Uploaders object");
