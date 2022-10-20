use strict;
use warnings;
use Test::More tests => 8;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

my $zip    = file(file($0)->dir, 'read_fromZipMember.zip');
my $antenna = RF::Antenna::Planet::MSI::Format->new;
isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

$antenna->read_fromZipMember($zip, 'zip/file/folder/antenna.msi');

isa_ok($antenna->header, 'HASH');
is($antenna->name,            'My Name', 'name');

isa_ok($antenna->horizontal, 'ARRAY');
isa_ok($antenna->vertical, 'ARRAY');
is(scalar(@{$antenna->horizontal}), 1, 'sizeof horizontal');
is(scalar(@{$antenna->vertical}), 1, 'sizeof vertical');
