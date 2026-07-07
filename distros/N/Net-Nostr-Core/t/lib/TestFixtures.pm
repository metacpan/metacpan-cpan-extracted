package TestFixtures;

use strictures 2;
use Exporter 'import';

our @EXPORT_OK = qw(%FIATJAF_EVENT @REAL_EVENTS make_event make_key_from_hex);

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

# Real, network-published events with genuine BIP-340 signatures, used to verify
# that signature validation interoperates with the wider Nostr ecosystem (NIP-01
# signs over the 32 raw bytes of the event id). Every entry below is an event
# accepted by real relays and other Nostr implementations.
our @REAL_EVENTS = (
    { %FIATJAF_EVENT },
    {
        id => 'f55c30722f056e330d8a7a6a9ba1522f7522c0f1ced1c93d78ea833c78a3d6ec',
        kind => 3,
        pubkey => 'f831caf722214748c72db4829986bd0cbb2bb8b3aeade1c959624a52a9629046',
        created_at => 1698412975,
        content => '',
        tags => [
            ['p', '4ddeb9109a8cd29ba279a637f5ec344f2479ee07df1f4043f3fe26d8948cfef9', '', ''],
            ['p', 'bb6fd06e156929649a73e6b278af5e648214a69d88943702f1fb627c02179b95', '', ''],
            ['p', 'b8b8210f33888fdbf5cedee9edf13c3e9638612698fe6408aff8609059053420', '', ''],
            ['p', '9dcee4fabcd690dc1da9abdba94afebf82e1e7614f4ea92d61d52ef9cd74e083', '', ''],
            ['p', '3eea9e831fefdaa8df35187a204d82edb589a36b170955ac5ca6b88340befaa0', '', ''],
            ['p', '885238ab4568f271b572bf48b9d6f99fa07644731f288259bd395998ee24754e', '', ''],
            ['p', '568a25c71fba591e39bebe309794d5c15d27dbfa7114cacb9f3586ea1314d126', '', ''],
        ],
        sig => '5092a9ffaecdae7d7794706f085ff5852befdf79df424cc3419bb797bf515ae05d4f19404cb8324b8b4380a4bd497763ac7b0f3b1b63ef4d3baa17e5f5901808',
    },
);

sub make_event {
    require Net::Nostr::Event;
    my %defaults = %FIATJAF_EVENT;
    delete @defaults{qw(id sig)};
    return Net::Nostr::Event->new(%defaults, @_);
}

sub make_key_from_hex {
    my ($hex_privkey) = @_;
    require Crypt::PK::ECC;
    require Net::Nostr::Key;
    my $pk = Crypt::PK::ECC->new;
    $pk->import_key_raw(pack('H*', $hex_privkey), 'secp256k1');
    my $key = bless {}, 'Net::Nostr::Key';
    $key->{_cryptpkecc} = $pk;
    return $key;
}

1;
