package # hide from PAUSE
    TDCSTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(
    qw<
        Artist
        Audiophile
        CD
        CDShop
        CDShopAudiophile
        Person
        Shop
        Track
    >,
);

1;
