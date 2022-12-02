use strict;
use warnings;
use Test::More tests => 4;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

my $file = "";

local $@;
eval{$antenna->read(\$file)};
my $error = $@;
ok($error, 'we died');
like($error, qr/is empty/);
