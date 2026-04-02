package TestFixtures;

use strictures 2;
use Exporter 'import';

our @EXPORT_OK = qw(%FIATJAF_EVENT make_event);

# A real-world note from fiatjaf
our %FIATJAF_EVENT = (
    id => 'deb8b23368b6c658c36cf16396927a045dee0b7707b4133d714fb67264cc10cc',
    kind => 1,
    pubkey => '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
    created_at => 1673361254,
    content => 'hello',
    tags => [],
    sig => 'f5e5e8a477c6749ef8562c23cdfec7a6917c975ec55075489cb3319b8a2ccb78317335a6850fb3a3714777b1c22611419d6c81ce4b0b88db86e2d1662bb17540'
);

sub make_event {
    require Net::Nostr::Event;
    return Net::Nostr::Event->new(@_);
}

1;
